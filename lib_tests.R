## We need to source it here
source(here::here("lib.R"))

test_readtext_base <- function() {
    x <- quanteda::corpus(
                       tmmv.read_text_base(here::here("testdata"),
                                           dvsep = "_", 
                                           docvarnames = c("Country", "Session", "Year")))
    
    ungd_files <- readtext::readtext(here::here("testdata"),
                                     docvarsfrom = "filenames",
                                     dvsep="_",
                                     docvarnames = c("Country", "Session", "Year"))
    y <- quanteda::corpus(ungd_files)
    for (i in sample(seq_len(quanteda::ndoc(x)), 100)) {
        testthat::expect_equal(x[i], y[i])
    }
}

test_lemmatize_words <- function() {
    ungd_files <- readtext::readtext(
                                here::here("testdata"),
                                dvsep = "_",
                                docvarnames = c("Country", "Session", "Year")
                            )

    ungd_files$doc_id <- stringr::str_replace(ungd_files$doc_id, ".txt", "") |>
        stringr::str_replace("_\\d{2}", "")
    
    ungd_corpus <- quanteda::corpus(ungd_files, text_field = "text")

    ungd_tokens <- quanteda::tokens(ungd_corpus,
                                    what = "word",
                                    remove_punct = TRUE,
                                    remove_symbols = TRUE,
                                    remove_numbers = TRUE,
                                    remove_url = TRUE,
                                    split_hyphens = FALSE,
                                    verbose = TRUE
                                    ) |>
        quanteda::tokens_tolower()
    
    ori_types <- attr(ungd_tokens, "types")
    textstem_lemmatized <- textstem::lemmatize_words(ori_types)
    our_lemmatized  <- tmmv.lemmatize_words(ori_types)
    testthat::expect_identical(textstem_lemmatized, our_lemmatized)
}

test_get_settings <- function() {
    x <- tmmv.get_settings(full = TRUE)
    testthat::expect_equal(length(x), 216)
    y <- tmmv.get_settings(full = FALSE)
    testthat::expect_equal(length(y), 12)
    testthat::expect_false(is.factor(y[[1]]$token_normalization))
    testthat::expect_true(is.character(y[[1]]$token_normalization))
}
    
test_get_settings()

if (dir.exists(here::here("testdata"))) {
    test_readtext_base()
    test_lemmatize_words()
}
