args <- tmmv.parse_args_read(slug = "chan")
settings <- tmmv.get_settings(full = FALSE, args = args)

library(here)

stopifnot(file.exists(here("rawdata/final_data.RDS")))

library(quanteda)
library(purrr)

# ref: https://osf.io/jdx6n (NB: it was written for quanteda < 3)

final_data <- readRDS(here("rawdata/final_data.RDS"))

current_tokens <- corpus(final_data$AB) |>
    tokens(
        remove_punct = TRUE,
        remove_numbers = TRUE,
        remove_symbols = TRUE,
        split_hyphens = TRUE
    ) |>
    tokens_tolower()

if (args$debug) {
    set.seed(1233)
    current_tokens <- tokens_sample(current_tokens, size = 300)
    cat("DEBUG: Only 300 documents are selected \n")
}

process_tokens <- function(setting, current_tokens, args) {
    ## print(setting)
    verbose <- args$debug
    if (setting$stopword_removal) {
        current_tokens <- current_tokens |>
            tokens_select(
                stopwords("english"),
                selection = "remove",
                padding = FALSE,
                verbose = verbose
            )
    }
    if (setting$token_normalization == "lemmatization") {
        ori_types <- attr(current_tokens, "types")
        lemma_types <- tmmv.lemmatize_words(ori_types)
        current_tokens <- tokens_replace(
            current_tokens,
            ori_types,
            lemma_types,
            valuetype = "fixed"
        )
    }
    if (setting$token_normalization == "stemming") {
        current_tokens <- tokens_wordstem(current_tokens)
    }
    current_dfm <- dfm(current_tokens)
    if (setting$trimming) {
        # We respect the original trimming scheme:
        # min_docfreq = 3, max_docfreq = floor(nrow(final_data) * 0.5)
        # i.e. the first one is a fixed number; the second is a proportion
        max_docfreq <- floor(ndoc(current_tokens) * 0.5)
        current_dfm <- current_dfm |>
            dfm_trim(
                min_docfreq = 3,
                max_docfreq = max_docfreq,
                docfreq_type = "count"
            )
    }
    current_hash <- rlang::hash(setting)
    ##print(current_hash)
    saveRDS(current_dfm, here(args$output_dir, paste0(current_hash, ".RDS")))
    ## thank you for your 16G of ram
    gc()
    invisible(NULL)
}

purrr::walk(
    settings,
    process_tokens,
    current_tokens = current_tokens,
    args = args,
    .progress = !args$debug
)

## DEBUG_MODE: test
if (args$debug) {
    library(testthat)
    output_dir <- args$output_dir
    for (setting in settings) {
        ## print(setting)
        filename <- paste0(rlang::hash(setting), ".RDS")
        testthat::expect_true(file.exists(here(output_dir, filename)))
        current_dfm <- readRDS(here(output_dir, filename))
        features <- featnames(current_dfm)
        if (setting$token_normalization == "none") {
            testthat::expect_true("cues" %in% features)
        }
        if (setting$token_normalization == "lemmatization") {
            testthat::expect_false("cues" %in% features)
            testthat::expect_true("cue" %in% features)
        }
        if (setting$token_normalization == "stemming") {
            testthat::expect_false("influence" %in% features)
            testthat::expect_true("influenc" %in% features)
        }
        if (setting$stopword_removal) {
            testthat::expect_false(all(purrr::map_lgl(
                stopwords("en"),
                ~ . %in% features
            )))
        } else {
            testthat::expect_true(any(purrr::map_lgl(
                stopwords("en"),
                ~ . %in% features
            )))
        }
        if (setting$trimming) {
            testthat::expect_true(
                topfeatures(current_dfm, scheme = "docfreq", n = 1) <= 150
            )
        } else {
            safe_feature <- current_dfm |>
                dfm_select("social") |>
                topfeatures(n = 1)
            testthat::expect_false(safe_feature <= 150)
        }
    }
}
