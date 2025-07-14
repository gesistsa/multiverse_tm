library(here)

args <- commandArgs(trailingOnly=TRUE)
if (length(args) == 0) {
    stop("You must provide the current run number, e.g. Rscript chan02_train.R 1")
}
current_run <- args[1]

if (current_run == "--debug") {
    DEBUG_MODE <- TRUE
    output_dir <- here("debug/chan/runs/1")
    unlink(output_dir, recursive = TRUE, force = TRUE)
    cat("DEBUG MODE ENABLED. Please check the artefacts in debug/chan/runs/1 \n")
} else {
    DEBUG_MODE <- FALSE
    output_dir <- here("intermediate/chan/runs", current_run)
}

library(keyATM)
library(quanteda)
## library(SnowballC)
library(seededlda)
library(purrr)

dir.create(output_dir, recursive = TRUE)
stopifnot(dir.exists(output_dir))

# ref: https://osf.io/jdx6n (NB: it was written for quanteda < 3)

settings <- expand.grid(token_normalization = c("none","lemmatization","stemming"),
                        stopword_removal = c(TRUE, FALSE),
                        trimming = c(TRUE, FALSE),
                        alternative_model = c(TRUE, FALSE),
                        k_setting = c(1,2,3), #K original, alt1, alt2
                        iteration_setting = c(1,2,3), #iter original, alt1, alt2
                        stringsAsFactors = FALSE) |>
    purrr::transpose()

if (DEBUG_MODE) {
    settings <- sample(settings, 10)
    cat("DEBUG MODE: Only 10 randomly selected settings will be checked.\n")
    cat("Rerun if you want more checks.\n")
}

train_model <- function(setting, output_dir, DEBUG_MODE, .fix_seed = NULL, .return_output = FALSE) {
    dfm_filename <- paste0(rlang::hash(setting[1:3]), ".RDS")
    if (!DEBUG_MODE) {
        dfm_dir <- "intermediate/chan"
    } else {
        print(setting)
        dfm_dir <- "debug/chan"
    }
    current_dfm <- readRDS(here(dfm_dir, dfm_filename))
    k <- c(39, 35, 43)
    iter_keyATM <- c(1500, round(1500 * 0.8), round(1500 * 1.2))
    iter_seededlda <- c(2000, round(2000 * 0.8), round(2000 * 1.2))
    current_k <- k[setting$k_setting]
    if (!setting$alternative_model) {
        current_iter <- iter_keyATM[setting$iteration_setting]
    } else {
        current_iter <- iter_seededlda[setting$iteration_setting]        
    }
    if (DEBUG_MODE) {
        cat("DEBUG MODE: Iteration setting is 100 (min. keyATM), should be: ", current_iter, "\n")
        current_iter <- 100
    }
    if (is.null(.fix_seed)) {
        random_seed <- sample(-65535:65535, 1)
    } else {
        random_seed <- .fix_seed
    }
    if (DEBUG_MODE) {
        cat("Current seed: ", random_seed, "\n")
    }
    output <- list()
    output$random_seed <- random_seed
    output$setting <- setting
    set.seed(random_seed)
    dict <- dictionary(list(socialmedia = c("facebook", "twitter", "blog*", "sns*", "tweet*", "blog*")))
    if (!setting$alternative_model) {
        key_docs <- keyATM_read(current_dfm)
        key_kw <- read_keywords(dictionary = dict, docs = key_docs)
        output$mod <- keyATM(key_docs,
                             no_keyword_topics = current_k,
                             keywords = key_kw,
                             model = "base",
                             options = list(iterations = current_iter,
                                            verbose = DEBUG_MODE))
    } else {
        output$mod <- textmodel_seededlda(x = current_dfm,
                                          dictionary = dict,
                                          valuetype = "glob",
                                          max_iter = current_iter,
                                          residual = current_k,
                                          verbose = DEBUG_MODE)
    }
    if (.return_output) {
        return(output)
    }
    current_hash <- rlang::hash(setting)
    saveRDS(output, file.path(output_dir, paste0(current_hash, ".RDS")))
}

purrr::walk(settings, train_model,
            output_dir = output_dir,
            DEBUG_MODE = DEBUG_MODE,
            .progress = !DEBUG_MODE)

if (DEBUG_MODE) {
    library(testthat)
    for (setting in settings) {
        current_hash <- rlang::hash(setting)
        testthat::expect_true(file.exists(file.path(output_dir, paste0(current_hash, ".RDS"))))
        output <- readRDS(file.path(output_dir, paste0(current_hash, ".RDS")))
        if (setting$alternative_model) {
            testthat::expect_true("textmodel_lda" %in% class(output$mod))
        } else {
            testthat::expect_true("keyATM_output" %in% class(output$mod))
            n_theta <- ncol(output$mod$theta)
        }
        expected_k <- c(39, 35, 43)[setting$k_setting] + 1
        expect_equal(expected_k, ncol(output$mod$theta))
        ## can't test iter
    }
    ## check reproducibility; only twice
    cat("Reproducibility check \n")
    repro_settings <- sample(settings, 2)
    for (setting in repro_settings) {
        current_hash <- rlang::hash(setting)
        testthat::expect_true(file.exists(file.path(output_dir, paste0(current_hash, ".RDS"))))
        output <- readRDS(file.path(output_dir, paste0(current_hash, ".RDS")))
        new_output <- train_model(setting,
                                  output_dir = output_dir,
                                  DEBUG_MODE = DEBUG_MODE,
                                  .fix_seed = output$random_seed,
                                  .return_output = TRUE)
        testthat::expect_equal(output$mod$theta[,1], new_output$mod$theta[,1])
    }
}
