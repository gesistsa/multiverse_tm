#' our base-only replacement of readtext::read_text
#' note that input_path is not a glob
tmmv.read_text_base <- function(input_path, dvsep, docvarnames) {
    if (dir.exists(input_path)) {
        txt_files <- list.files(input_path, recursive = TRUE)
        txt_content <- vapply(txt_files,
                              function(x) paste(suppressWarnings(readLines(file.path(input_path, x))),
                                            collapse = "\n"),
                              character(1))
    } else {
        ## assume to be an archive
        txt_files <- archive::archive(input_path)$path
        txt_content <- vapply(txt_files, function(x)
            paste(suppressWarnings(readLines(
                archive::archive_read(archive = input_path, file = x))),
                collapse = "\n"), character(1))
    }

    output <- data.frame(text = txt_content, stringsAsFactors = FALSE)
    output$doc_id <- basename(txt_files)

    meta <- strsplit(tools::file_path_sans_ext(output$doc_id), dvsep, fixed = TRUE)
    
    meta_df <- as.data.frame(do.call(rbind, meta))
    colnames(meta_df) <- docvarnames
    meta_df <- lapply(meta_df, function(x) type.convert(as.character(x), as.is = TRUE))
    meta_df <- data.frame(meta_df, stringsAsFactors = FALSE)
    output <- cbind(output, meta_df)
    return(output)
}

#' A replacement of textstem::lemmatize_words
tmmv.lemmatize_words <- function(tokens) {
    token_matches <- match(tokens, lexicon::hash_lemmas[[1]])
    tokens[!is.na(token_matches)] <- lexicon::hash_lemmas[
        token_matches[!is.na(token_matches)],
    ][[2]]
    return(tokens)
}

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
            output$args <- args[seq(args_index+1,
                                    length(args))]
        }
    }
    filearg <- grep("--file=", args, value = TRUE)[1]
    output$filename <- gsub("--file=", "", filearg)
    class(args) <- append(class(args), "tmmv_args")
    return(output)
}

tmmv.parse_args_read <- function(slug = "chan") {
    args <- tmmv.parse_args()
    args$slug <- slug
    if (!args$debug) {
        args$output_dir <- paste0("intermediate/", slug)
        return(args)
    }
    args$output_dir <- paste0("debug/", slug)
    unlink(args$output_dir, recursive = TRUE, force = TRUE)
    dir.create(args$output_dir, recursive = TRUE, showWarnings = FALSE)
    message("DEBUG MODE ENABLED. Please check the artefacts in",
        args$output_dir,
        "\n")
    return(args)
}

tmmv.parse_args_train <- function(slug = "chan", debug = FALSE, .current_run = NULL) {
    if (debug) {        
        args <- tmmv.parse_args(c("/usr/lib/R/bin/exec/R","--no-echo","--no-restore", "--file=fake.R", "--args", "--debug"))
    } else {
        args <- tmmv.parse_args()
    }
    args$slug <- slug
    if (!args$debug && is.null(args$arg) && is.null(.current_run)) {
        msg <- paste("You must provide the current run number, e.g. Rscript",
                     args$filename,
                     "1")
        stop(msg, call. = FALSE)
    }
    if (!args$debug) {
        args$current_run <- ifelse(is.null(.current_run), args$args[1], .current_run)
        args$prefix <- "intermediate"
        args$output_dir <- here::here(args$prefix, slug, "runs", args$current_run)
    } else {
        args$current_run <- "1"
        args$prefix <- "debug"
        output_display <- paste0(args$prefix, "/", slug, "/1")
        message("DEBUG MODE ENABLED. Please check the artefacts in ",
            output_display,
            "\n")
        unlink(here::here(args$prefix, slug, args$current_run), recursive = TRUE, force = TRUE)
        args$output_dir <- here::here(args$prefix, slug, args$current_run)
    }
    dir.create(args$output_dir, recursive = TRUE, showWarnings = FALSE)
    stopifnot(dir.exists(args$output_dir))
    return(args)
}

## for #14
tmmv.get_settings <- function(full = TRUE, args = NULL, .nothing_quit = TRUE) {
    settings <- list(token_normalization = c("none","lemmatization","stemming"),
                     stopword_removal = c(TRUE, FALSE),
                     trimming = c(TRUE, FALSE))
    if (full) {
        settings$alternative_model = c(TRUE, FALSE)
        settings$k_setting = c(1,2,3) #K original, alt1, alt2
        settings$iteration_setting = c(1,2,3) #iter original, alt1, alt2
    }
    output <- purrr::transpose(expand.grid(settings, stringsAsFactors = FALSE))
    ## no filtering
    if (is.null(args) || (!is.null(args) && args$debug)) {
        return(output)
    }
    ## filtering
    all_artefacts <- list.files(args$output_dir, pattern = "\\.RDS$")
    output <- purrr::discard(output, function(x) paste0(rlang::hash(x), ".RDS") %in% all_artefacts)
    if (length(output) == 0 && .nothing_quit) {
        quit("no", status = 0)
    }
    return(output)
}

#' generate all parameters for TM training
#' @param keywords LIST, not quanteda::dictionary
#' @param stemmed_keywords LIST!
tmmv.get_current <- function(setting, args,
                             keywords = NULL, stemmed_keywords = NULL,
                             k, original_iter, alternative_iter = NULL,
                             .fix_seed = NULL) {
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
    if (setting$token_normalization != "stemming" || is.null(stemmed_keywords)) {
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
        message("DEBUG MODE: Iteration setting is 100 (min. keyATM), should be: ", current$iter, "\n")
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
