# Sourcing code licensed differently
source(here::here("lib/read_text_base.R"))
source(here::here("lib/lemmatize_words.R"))
source(here::here("lib/plot_spec_curve.R"))
source(here::here("lib/calculate_icc.R"))
source(here::here("lib/check_keywords.R"))
# common data
source(here::here("lib/data.R"))

tmmv.parse_args <- function(args = commandArgs()) {
    output <- list()
    output$debug <- "--debug" %in% args
    args <- setdiff(args, "--debug")
    args_index <- which(args == "--args")
    if (identical(args_index, integer(0))) {
        output$args <- NULL
    } else {
        if (args_index[1] == length(args)) {
            output$args <- NULL
        } else {
            output$args <- args[seq(args_index + 1, length(args))]
        }
    }
    filearg <- grep("--file=", args, value = TRUE)[1]
    output$filename <- gsub("--file=", "", filearg)
    class(args) <- append(class(args), "tmmv_args")
    return(output)
}

## a reusable function to create `args$output_dir`
tmmv.create_dir <- function(args, ontop = NULL, clean = FALSE) {
    output_dir <- args$output_dir
    if (!is.null(ontop)) {
        output_dir <- fs::path(output_dir, ontop)
    }
    if (clean && fs::dir_exists(output_dir)) {
        fs::dir_delete(output_dir)
    }
    fs::dir_create(output_dir, recurse = TRUE)
    return(invisible(output_dir))
}

tmmv.parse_args_read <- function(slug = "chan") {
    args <- tmmv.parse_args()
    args$slug <- slug
    if (!args$debug) {
        args$output_dir <- fs::path("intermediate/", slug)
        return(args)
    }
    args$output_dir <- fs::path("debug/", slug)
    tmmv.create_dir(args, clean = TRUE)
    message(
        "DEBUG MODE ENABLED. Please check the artefacts in",
        args$output_dir,
        "\n"
    )
    return(args)
}

tmmv.parse_args_train <- function(
    slug = "chan",
    debug = FALSE,
    .current_run = NULL
) {
    if (debug) {
        args <- tmmv.parse_args(c(
            "/usr/lib/R/bin/exec/R",
            "--no-echo",
            "--no-restore",
            "--file=fake.R",
            "--args",
            "--debug"
        ))
    } else {
        args <- tmmv.parse_args()
    }
    args$slug <- slug
    if (rlang::is_interactive() && is.null(.current_run)) {
        .current_run <- 1
    }
    if (!args$debug && is.null(args$arg) && is.null(.current_run)) {
        msg <- paste(
            "You must provide the current run number, e.g. Rscript",
            args$filename,
            "1"
        )
        stop(msg, call. = FALSE)
    }
    if (!args$debug) {
        args$current_run <- ifelse(
            is.null(.current_run),
            args$args[1],
            .current_run
        )
        args$prefix <- "intermediate"
        args$output_dir <- here::here(
            args$prefix,
            slug,
            "runs",
            args$current_run
        )
    } else {
        args$current_run <- "1"
        args$prefix <- "debug"
        output_display <- paste0(args$prefix, "/", slug, "/1")
        message(
            "DEBUG MODE ENABLED. Please check the artefacts in ",
            output_display,
            "\n"
        )
        args$output_dir <- here::here(args$prefix, slug, args$current_run)
    }
    tmmv.create_dir(args, clean = args$debug)
    return(args)
}

## only because it happens frequently
tmmv.get_rds_filename <- function(setting, output_dir = NULL) {
    rds_filename <- paste0(rlang::hash(setting), ".RDS")
    if (is.null(output_dir)) {
        return(rds_filename)
    }
    return(fs::path(output_dir, rds_filename))
}

## for #14
tmmv.get_settings <- function(full = TRUE, args = NULL, .nothing_quit = TRUE) {
    settings <- list(
        token_normalization = c("none", "lemmatization", "stemming"),
        stopword_removal = c(TRUE, FALSE),
        trimming = c(TRUE, FALSE)
    )
    if (full) {
        settings$alternative_model = c(TRUE, FALSE)
        settings$k_setting = c(1, 2, 3) #K original, alt1, alt2
        settings$iteration_setting = c(1, 2, 3) #iter original, alt1, alt2
    }
    output <- purrr::transpose(expand.grid(settings, stringsAsFactors = FALSE))
    ## no filtering
    if (is.null(args) || (!is.null(args) && args$debug)) {
        return(output)
    }
    ## filtering
    all_artefacts <- list.files(args$output_dir, pattern = "\\.RDS$")
    output <- purrr::discard(output, function(x) {
        tmmv.get_rds_filename(x) %in% all_artefacts
    })
    if (length(output) == 0 && .nothing_quit) {
        quit("no", status = 0)
    }
    return(output)
}

#' generate all parameters for TM training
#' @param keywords LIST, not quanteda::dictionary
#' @param stemmed_keywords LIST!
tmmv.get_current <- function(
    setting,
    args,
    keywords = NULL,
    stemmed_keywords = NULL,
    k,
    original_iter,
    alternative_iter = NULL,
    .fix_seed = NULL
) {
    stopifnot(length(k) == 3)
    stopifnot(length(original_iter) == 3)
    if (!is.null(alternative_iter)) {
        stopifnot(length(alternative_iter) == 3)
    }
    if (!is.null(keywords)) {
        stopifnot(is.list(keywords))
    }
    if (!is.null(stemmed_keywords)) {
        stopifnot(is.list(stemmed_keywords))
    }

    current <- list()
    if (
        setting$token_normalization != "stemming" || is.null(stemmed_keywords)
    ) {
        current$keywords <- keywords
    } else {
        current$keywords <- stemmed_keywords
    }
    current$k <- k[setting$k]
    if (!setting$alternative_model || is.null(alternative_iter)) {
        current$iter <- original_iter[setting$iteration_setting]
    }
    if (setting$alternative_model && !is.null(alternative_iter)) {
        current$iter <- alternative_iter[setting$iteration_setting]
    }
    if (args$debug) {
        message(
            "DEBUG MODE: Iteration setting is 100 (min. keyATM), should be: ",
            current$iter,
            "\n"
        )
        current$iter <- 100
    }
    if (is.null(.fix_seed)) {
        current$random_seed <- sample(-65535:65535, 1)
    } else {
        current$random_seed <- .fix_seed
    }
    if (args$debug) {
        message("Current seed: ", current$random_seed, "\n")
    }
    return(current)
}

#' return the column index in theta, which the column vector
#' has the highest spearman's correlation with anchor_theta
tmmv.find_anchor <- function(anchor_theta, theta) {
    stopifnot(length(anchor_theta) == nrow(theta))
    cor_coefs <- vapply(
        seq_len(ncol(theta)),
        FUN = function(x) {
            cor(anchor_theta, theta[, x], method = "spearman")
        },
        FUN.VALUE = numeric(1)
    )
    return(which.max(cor_coefs))
}

#' This function unifies the theta so that the output theta always
#' has the same nrow as current_dfm
#' The raison d'être is that stm discards empty rows sliently
#' But doesn't retain the rownames
tmmv.unify_theta <- function(mod, trimmed_dfm, current_dfm) {
    theta <- mod$theta
    rownames(theta) <- docnames(trimmed_dfm)

    excluded_docs <- setdiff(docnames(current_dfm), docnames(trimmed_dfm))
    k <- ncol(theta)
    fake_theta <- matrix(
        rep(1 / k, length(excluded_docs) * k),
        nrow = length(excluded_docs),
        ncol = k
    )
    rownames(fake_theta) <- excluded_docs
    final_theta <- rbind(theta, fake_theta)

    final_theta <- final_theta[
        match(rownames(current_dfm), rownames(final_theta)),
    ]
    return(final_theta)
}

# Best to use for plots with 2 colors
# (orange and purple)
# Do NOT use if there are more than 4 overlapping items
tmmv.colors <- list(
    orange = "#F08741",
    berrypurple = "#642878",
    lightblue = "#1E8CC8",
    yellow = "#FAD205",
    pink = "#D20064"
)

# Color palette proposed by Okabe & Ito
# See: https://web.archive.org/web/20210209175206im_/http://jfly.iam.u-tokyo.ac.jp/color/image/pallete.jpg
tmmv.palette_safe <- list(
    orange = grDevices::rgb(230, 159, 0, maxColorValue = 255),
    blue = grDevices::rgb(86, 180, 233, maxColorValue = 255),
    green = grDevices::rgb(0, 158, 155, maxColorValue = 255),
    yellow = grDevices::rgb(240, 228, 66, maxColorValue = 255),
    darkblue = grDevices::rgb(0, 114, 178, maxColorValue = 255),
    vermilion = grDevices::rgb(213, 94, 0, maxColorValue = 255),
    purple = grDevices::rgb(204, 121, 167, maxColorValue = 255)
)

tmmv.download_from_osf <- function(osf_handle, output_dir = "rawdata") {
    outcome <- osfr::osf_retrieve_file(osf_handle) |>
        osfr::osf_download(
            path = here::here(output_dir),
            conflicts = "skip",
            progress = TRUE
        )
    stopifnot(file.exists(outcome$local_path[1]))
    invisible(outcome)
}

# for use with 03_combine for czymara, takano, and tvinnereim
tmmv.get_effect_size_mod <- function(
    setting,
    anchor_theta,
    args,
    .get_keyatm_strata_topic_func,
    .get_stm_estimate_func
) {
    current_mod <- readRDS(tmmv.get_rds_filename(
        setting,
        here(args$output_dir)
    ))
    set.seed(current_mod$random_seed)
    k <- ncol(current_mod$theta)
    if (setting$alternative_model) {
        strata_topic <- .get_keyatm_strata_topic_func(current_mod)
        theta1 <- strata_topic$theta[[1]]
        theta2 <- strata_topic$theta[[2]]
        theta_diff <- theta2[, seq_len(k)] - theta1[, seq_len(k)]
        theta_diff_quantile <- apply(theta_diff, 2, quantile, c(0.025, 0.975))
        theta_diff_mean <- apply(theta_diff, 2, mean)
        anchor_index <- tmmv.find_anchor(anchor_theta, current_mod$theta)
        output <- data.frame(
            Estimate = theta_diff_mean[anchor_index],
            Q2.5 = theta_diff_quantile[1, anchor_index],
            Q97.5 = theta_diff_quantile[2, anchor_index]
        )
        rownames(output) <- NULL
    } else {
        res <- .get_stm_estimate_func(current_mod)
        anchor_index <- tmmv.find_anchor(anchor_theta, current_mod$theta)
        output <- data.frame(
            Estimate = as.vector(res$means)[anchor_index],
            Q2.5 = res$cis[[anchor_index]][1],
            Q97.5 = res$cis[[anchor_index]][2]
        )
        colnames(output) <- c("Estimate", "Q2.5", "Q97.5")
        rownames(output) <- NULL
    }
    output <- round(output, 6)
    estimate <- cbind(as.data.frame(setting), output)
    theta <- current_mod$theta[, anchor_index]
    return(list(estimate = estimate, theta = theta))
}

tmmv.postprocess_effect_size_mod <- function(res, args) {
    ## only for the side effect
    output_path <- here::here(
        "results",
        "aggregated",
        args$slug,
        paste0(args$current_run, ".csv")
    )
    res |>
        purrr::map("estimate") |>
        purrr::list_rbind() |>
        write.csv(output_path, row.names = FALSE)

    tmmv.create_dir(args, ontop = "theta")

    theta <- res |> purrr::map("theta")
    names(theta) <- purrr::map_chr(settings, \(x) rlang::hash(x))
    saveRDS(theta, fs::path(args$output_dir, "theta", "theta.RDS"))
    invisible(NULL)
}

tmmv.cache_requirements <- function() {
    rpkgs <- sort(unique(renv::dependencies(quiet = TRUE)$Package))
    system_requirements <- pak::pkg_sysreqs(setdiff(
        rpkgs,
        c("RMeCab", "colorblindr")
    ))
    rpkgs[
        rpkgs == "RMeCab"
    ] <- "IshidaMotohiro/RMeCab@2a11093f6a69ee11584aa0e2e8b32a59d1b9f092"

    rpkgs[
        rpkgs == "colorblindr"
    ] <- "clauswilke/colorblindr"

    aptpkgs <- unique(c(
        "curl",
        "make",
        setdiff(
            as.character(system_requirements$packages$system_packages),
            c("pandoc-citeproc")
        ),
        "mecab",
        "libmecab-dev",
        "mecab-ipadic-utf8"
    ))

    jsonlite::write_json(
        list(rpkgs = rpkgs, aptpkgs = aptpkgs),
        here::here("dev", "requirements.json")
    )
    invisible(NULL)
}

## reading theta generated via 03_combine.R scripts (or 02a_theta.R for chan)
tmmv.read_thetas <- function(slug, runs = c(1, 2, 3)) {
    .extract_sdg <- function(x, topic_label = "SDG10") {
        output <- x[, which(stringr::str_detect(colnames(x), topic_label))]
        names(output) <- NULL
        return(output)
    }
    .f <- function(run, slug) {
        path <- here::here("intermediate", slug, "runs", run, "theta/theta.RDS")
        if (fs::file_exists(path)) {
            if (slug == "jankin") {
                content <- readRDS(path)
                output <- purrr::map(content, .extract_sdg)
                names(output) <- names(content)
                return(output)
            } else {
                return(readRDS(path))
            }
        }
        NULL
    }
    purrr::map(runs, .f = .f, slug = slug) |> purrr::discard(is.null)
}
