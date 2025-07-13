args <- commandArgs(trailingOnly=TRUE)

library(here)

if ("--debug" %in% args) {
    DEBUG_MODE <- TRUE
    unlink(here("debug/un"), recursive = TRUE, force = TRUE)
    dir.create(here("debug/un"), recursive = TRUE, showWarnings = FALSE)
    print("DEBUG MODE ENABLED. Please check the artefacts in debug/un")
} else {
    DEBUG_MODE <- FALSE
}

library(readtext)
library(quanteda)
library(stringr)
# library(textstem) don't import it, but use it here
library(purrr)

stopifnot(dir.exists(here("rawdata/un/TXT")))

## Modified from the original RMD file

ungd_files <- readtext(here("rawdata/un/TXT/*"), 
                                 docvarsfrom = "filenames", 
                                 dvsep="_", 
                                 docvarnames = c("Country", "Session", "Year"))

ungd_files$doc_id <- str_replace(ungd_files$doc_id , ".txt", "") |>
    str_replace("_\\d{2}", "")

ungd_corpus <- corpus(ungd_files, text_field = "text") 

if (DEBUG_MODE) {
    set.seed(1233)
    ungd_corpus <- corpus_sample(ungd_corpus, size = 300)
    print("Only 300 documents are selected")
    
}

## Removed the stopword removal
ungd_tokens <- tokens(ungd_corpus, what = "word",
                 remove_punct = TRUE,
                 remove_symbols = TRUE,
                 remove_numbers = TRUE,
                 remove_url = TRUE,
                 split_hyphens = FALSE,
                 verbose = DEBUG_MODE) |>
    tokens_tolower()


settings <- expand.grid(token_normalization = c("none","lemmatization","stemming"),
                        stopword_removal = c(TRUE, FALSE),
                        trimming = c(TRUE, FALSE), stringsAsFactors = FALSE) |>
    purrr::transpose()

process_tokens <- function(setting, current_tokens, verbose = FALSE) {
    ## print(setting)
    if (setting$stopword_removal) {
        current_tokens <- current_tokens |>
            tokens_select(stopwords("english"), selection = "remove",
                          padding = FALSE, verbose = verbose)
    }
    ## This tokens_select is kind of unreasonable, but let's keep it
    current_tokens <- current_tokens |>
        tokens_select(c("[\\d-]", "[[:punct:]]", "^.{1}$", "us",
                        "united_nations", "united", "nations"),
                      selection = "remove", 
                      valuetype="regex", 
                      min_nchar = 2L,
                      verbose = verbose)
    if (setting$token_normalization == "lemmatization") {
        ori_types <- attr(current_tokens, "types")
        lemma_types <- textstem::lemmatize_words(ori_types)
        current_tokens <- tokens_replace(current_tokens, ori_types, lemma_types,
                                      valuetype = "fixed")        
    }
    if (setting$token_normalization == "stemming") {
        current_tokens <- tokens_wordstem(current_tokens)        
    }
    temp_dfm <- current_tokens |>
        tokens_select(min_nchar = 2) |>
        tokens_ngrams(n = 1:2) |> dfm()
    if (setting$trimming) {
        temp_dfm <- temp_dfm |>
            dfm_trim(min_docfreq = 0.005, max_docfreq = 0.5,
                     docfreq_type = "prop", verbose = verbose)
    }
    current_hash <- rlang::hash(setting)
    ##print(current_hash)
    if (!DEBUG_MODE) {
        output_dir <- "intermediate/un/"
    } else {
        output_dir <- "debug/un"
    }
    saveRDS(temp_dfm, here(output_dir, paste0(current_hash, ".RDS")))
    ## thank you for your 16G of ram
    gc()
    invisible(NULL)
}

## Stupid but we only do it once
purrr::walk(settings, process_tokens, current_tokens = ungd_tokens, verbose = DEBUG_MODE, .progress = !DEBUG_MODE)

## DEBUG_MODE: test
if (DEBUG_MODE) {
    library(testthat)
    output_dir <- "debug/un"
    for (setting in settings) {
        filename <- paste0(rlang::hash(setting), ".RDS")
        expect_true(file.exists(here(output_dir, filename)))
        current_dfm <- readRDS(here(output_dir, filename))
        features <- featnames(current_dfm)
        if (setting$token_normalization == "none") {
            expect_true("accorded" %in% features)
        }
        if (setting$token_normalization == "lemmatization") {
            expect_false("accorded" %in% features)
            expect_true("accord" %in% features)
        }
        if (setting$token_normalization == "stemming") {
            expect_false("debate" %in% features)
            expect_true("debat" %in% features)
        }
        if (setting$stopword_removal) {
            expect_false(all(purrr::map_lgl(stopwords("en"), ~. %in% features)))
        } else {
            expect_true(any(purrr::map_lgl(stopwords("en"), ~. %in% features)))            
        }
        if (setting$trimming) {
            expect_true(topfeatures(current_dfm, scheme = "docfreq", n = 1) <= 150)
        } else {
            expect_false(topfeatures(current_dfm, scheme = "docfreq", n = 1) <= 150)
        }
    }
}
