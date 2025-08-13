args <- tmmv.parse_args_train(slug = "takano")
settings <- tmmv.get_settings(full = TRUE, args = args)

settings <- settings |>
    purrr::keep(\(x) x$token_normalization != "stemming")

library(here)
library(keyATM)
library(quanteda)
library(purrr)
library(stm)
library(dplyr)

if (args$debug) {
    settings <- sample(settings, 10)
    cat("DEBUG MODE: Only 10 randomly selected settings will be checked.\n")
    cat("Rerun if you want more checks.\n")
}

## REMOVE THIS WHEN #44 is merged
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

train_model <- function(
    setting,
    args,
    .fix_seed = NULL,
    .return_output = FALSE
) {
    dfm_filename <- paste0(rlang::hash(setting[1:3]), ".RDS")
    current_dfm <- readRDS(here(args$prefix, args$slug, dfm_filename))

    current <- tmmv.get_current(
        setting = setting,
        args = args,
        k = c(7, 6, 8),
        original_iter = c(500, round(500 * 0.8), round(500 * 1.2)),
        alternative_iter = c(2000, round(2000 * 0.8), round(2000 * 1.2)),
        .fix_seed = .fix_seed
    )

    output <- list()
    output$random_seed <- current$random_seed
    output$setting <- setting

    ## STM drops rows silently, we do it here explicitly
    rowsum_priv <- apply(current_dfm, 1, sum)
    trimmed_dfm <- current_dfm[rowsum_priv != 0, ]

    set.seed(current$random_seed)
    meta <- select(trimmed_dfm@docvars, -age) ## there is one NA
    if (!setting$alternative_model) {
        output$mod <- stm(
            trimmed_dfm,
            K = current$k,
            init.type = "Spectral",
            max.em.its = current$iter,
            prevalence = ~ time +
                selfLoss +
                connectedness +
                vastness +
                physiological +
                accommodation,
            verbose = args$debug,
            data = meta
        )
    } else {
        keyATM_docs <- keyATM_read(texts = trimmed_dfm)

        output$mod <- weightedLDA(
            docs = keyATM_docs,
            number_of_topics = current$k,
            model = "covariates",
            model_settings = list(
                covariates_data = meta,
                covariates_formula = ~ time +
                    selfLoss +
                    connectedness +
                    vastness +
                    physiological +
                    accommodation
            ),
            options = list(
                iterations = current$iter,
                verbose = args$debug
            )
        )
    }
    output$theta <- tmmv.unify_theta(output$mod, trimmed_dfm, current_dfm)
    output$docvars <- meta
    if (.return_output) {
        return(output)
    }
    current_hash <- rlang::hash(setting)
    saveRDS(output, file.path(args$output_dir, paste0(current_hash, ".RDS")))
}

purrr::walk(settings, train_model, args = args, .progress = !args$debug)

if (args$debug) {
    library(testthat)
    for (setting in settings) {
        current_hash <- rlang::hash(setting)
        testthat::expect_true(file.exists(file.path(
            args$output_dir,
            paste0(current_hash, ".RDS")
        )))
        output <- readRDS(file.path(
            args$output_dir,
            paste0(current_hash, ".RDS")
        ))
        if (setting$alternative_model) {
            testthat::expect_true("keyATM_output" %in% class(output$mod))
        } else {
            testthat::expect_true("STM" %in% class(output$mod))
        }
        expected_k <- c(7, 6, 8)[setting$k_setting]
        expect_equal(expected_k, ncol(output$theta))
        ## can't test iter
        ## output$theta
        dfm_filename <- paste0(rlang::hash(setting[1:3]), ".RDS")
        current_dfm <- readRDS(here(args$prefix, args$slug, dfm_filename))
        expect_equal(ndoc(current_dfm), nrow(output$theta))
        expect_equal(ndoc(current_dfm), nrow(output$theta))
        expect_equal(expected_k, ncol(output$theta))
        cat("Reproducibility check \n")
        repro_settings <- sample(settings, 2)
        for (setting in repro_settings) {
            current_hash <- rlang::hash(setting)
            testthat::expect_true(file.exists(file.path(
                args$output_dir,
                paste0(current_hash, ".RDS")
            )))
            output <- readRDS(file.path(
                args$output_dir,
                paste0(current_hash, ".RDS")
            ))
            print("seed:")
            print(output$random_seed)
            new_output <- train_model(
                setting,
                args = args,
                .fix_seed = output$random_seed,
                .return_output = TRUE
            )
            testthat::expect_equal(
                output$mod$theta[, 1],
                new_output$mod$theta[, 1]
            )
        }
    }
}
