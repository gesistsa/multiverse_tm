args <- tmmv.parse_args_train(slug = "jankin")
settings <- tmmv.get_settings(full = TRUE, args = args)

library(here)
library(keyATM)
library(quanteda)
library(SnowballC)
library(seededlda)
library(furrr)

sdg_keywords <- tmmv.data[[args$slug]]$dict

## This is not working because we stemmed first, before doing bigram in jankin01
## sdg_keywords_stemmed <- lapply(sdg_keywords, SnowballC::wordStem)

split_keywords <- lapply(sdg_keywords, strsplit, split = "_")

stemmed_sdg_keywords <- list()

for (i in seq_len(length(split_keywords))) {
    stemmed_sdg_keywords[[i]] <- unique(vapply(
        lapply(split_keywords[[i]], SnowballC::wordStem),
        paste,
        collapse = "_",
        FUN.VALUE = character(1)
    ))
}

names(stemmed_sdg_keywords) <- names(sdg_keywords)

if (args$debug) {
    settings <- sample(settings, 10)
    cat("DEBUG MODE: Only 10 randomly selected settings will be checked.\n")
    cat("Rerun if you want more checks.\n")
}

train_model <- function(
    setting,
    args,
    sdg_keywords,
    stemmed_sdg_keywords,
    .fix_seed = NULL,
    .return_output = FALSE
) {
    current_dfm <- readRDS(tmmv.get_rds_filename(
        setting[1:3],
        here(args$prefix, args$slug)
    ))

    current <- tmmv.get_current(
        setting = setting,
        args = args,
        keywords = sdg_keywords,
        stemmed_keywords = stemmed_sdg_keywords,
        k = tmmv.data[[args$slug]]$k,
        original_iter = c(1500, round(1500 * 0.8), round(1500 * 1.2)),
        alternative_iter = c(2000, round(2000 * 0.8), round(2000 * 1.2)),
        .fix_seed = .fix_seed
    )
    # find fully pruned topics
    ATM_docs <- keyATM_read(current_dfm)
    available_topics <- tmmv.check_keywords(ATM_docs, current$keywords)
    if (args$debug) {
        cat("Available topics: ", length(available_topics), "\n")
    }
    n_fully_pruned_topics <- length(current$keywords) - length(available_topics)
    if (n_fully_pruned_topics > 0) {
        # compensate the fully pruned topics by adding it to the current_k
        current$k <- current$k + n_fully_pruned_topics
        current$keywords <- current$keywords[available_topics]
    }

    output <- list()
    output$random_seed <- current$random_seed
    output$setting <- setting

    set.seed(current$random_seed)

    if (!setting$alternative_model) {
        output$mod <- keyATM(
            docs = ATM_docs,
            no_keyword_topics = current$k,
            keywords = current$keywords,
            model = "base",
            options = list(
                iterations = current$iter,
                prune = TRUE,
                verbose = args$debug
            )
        )
    } else {
        output$mod <- textmodel_seededlda(
            x = current_dfm,
            dictionary = quanteda::dictionary(current$keywords),
            valuetype = "fixed",
            max_iter = current$iter,
            residual = current$k,
            verbose = args$debug
        )
    }
    if (.return_output) {
        return(output)
    }
    current_hash <- rlang::hash(setting)
    saveRDS(output, tmmv.get_rds_filename(setting, args$output_dir))
}

if (args$debug) {
    plan(sequential)
} else {
    plan(multisession, workers = getOption("tmmv.jankin.workers", 1))
}

furrr::future_walk(
    settings,
    train_model,
    args = args,
    sdg_keywords = sdg_keywords,
    stemmed_sdg_keywords = stemmed_sdg_keywords,
    .progress = !args$debug
)

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
            testthat::expect_true("textmodel_lda" %in% class(output$mod))
        } else {
            testthat::expect_true("keyATM_output" %in% class(output$mod))
            n_theta <- ncol(output$mod$theta)
        }
        expected_k <- tmmv.data[[args$slug]]$k[setting$k_setting] +
            length(tmmv.data[[args$slug]]$dict)
        expect_equal(expected_k, ncol(output$mod$theta))
        ## can't test iter
    }
    ## check reproducibility; only twice
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
        new_output <- train_model(
            setting,
            args = args,
            sdg_keywords = sdg_keywords,
            stemmed_sdg_keywords = stemmed_sdg_keywords,
            .fix_seed = output$random_seed,
            .return_output = TRUE
        )
        testthat::expect_equal(output$mod$theta[, 1], new_output$mod$theta[, 1])
    }
}
