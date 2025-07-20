source(here::here("lib.R"))

library(quanteda)

process_tokens_maier <- function(setting, current_tokens) {
    if (setting$stopword_removal) {
        current_tokens <- current_tokens |>
            tokens_select(stopwords("english"), selection = "remove",
                          padding = FALSE, verbose = TRUE)
    }
    if (setting$token_normalization == "lemmatization") {
        ori_types <- attr(current_tokens, "types")
        lemma_types <- tmmv.lemmatize_words(ori_types)
        current_tokens <- tokens_replace(current_tokens, ori_types, lemma_types,
                                      valuetype = "fixed", verbose = TRUE)
    }
    if (setting$token_normalization == "stemming") {
        current_tokens <- tokens_wordstem(current_tokens, verbose = TRUE)
    }
    current_tokens
    ## current_tokens |>
    ##     tokens_select(min_nchar = 2) |>
    ##     tokens_ngrams(n = 1:2) |> dfm()
}

process_tokens_alternative <- function(setting, current_tokens) {
    if (setting$token_normalization == "lemmatization") {
        ori_types <- attr(current_tokens, "types")
        lemma_types <- tmmv.lemmatize_words(ori_types)
        current_tokens <- tokens_replace(current_tokens, ori_types, lemma_types,
                                      valuetype = "fixed", verbose = TRUE)
    }
    if (setting$token_normalization == "stemming") {
        current_tokens <- tokens_wordstem(current_tokens)
    }
    if (setting$stopword_removal) {
        current_tokens <- current_tokens |>
            tokens_select(stopwords("english"), selection = "remove",
                          padding = FALSE, verbose = TRUE)
    }
    current_tokens
    ## current_tokens |>
    ##     tokens_select(min_nchar = 2) |>
    ##     tokens_ngrams(n = 1:2) |> dfm()
}

## our shuffled corpus
ungd_files <-tmmv.read_text_base(here::here("tests/TXT"),
                                 dvsep = "_", 
                                 docvarnames = c("Country", "Session", "Year"))

ungd_files$doc_id <- stringr::str_replace(ungd_files$doc_id , ".txt", "") |>
    stringr::str_replace("_\\d{2}", "")

set.seed(721831)
ungd_corpus <- corpus_sample(corpus(ungd_files, text_field = "text"), 10)

settings <- tmmv.get_settings(full = FALSE)

ungd_tokens <- tokens(ungd_corpus, what = "word",
                      remove_punct = TRUE,
                      remove_symbols = TRUE,
                      remove_numbers = TRUE,
                      remove_url = TRUE,
                      split_hyphens = FALSE,
                      verbose = FALSE) |>
    tokens_tolower()

a <- purrr::map(settings, process_tokens_maier, current_tokens = ungd_tokens, verbose = FALSE)
b <- purrr::map(settings, process_tokens_alternative, current_tokens = ungd_tokens, verbose = FALSE)    
res <- purrr::map2_lgl(a, b, function(x, y) identical(attr(x, "types"), attr(y, "types")))

x <- process_tokens_maier(settings[[2]], ungd_tokens)
y <- process_tokens_alternative(settings[[2]], ungd_tokens)


## To narrow it even further

does_tokens <- as.tokens(list(c(as.character(ungd_tokens)[140:160], as.character(ungd_tokens)[2250:2258])))

c <- purrr::map(settings, process_tokens_maier, current_tokens = does_tokens, verbose = FALSE)
d <- purrr::map(settings, process_tokens_alternative, current_tokens = does_tokens, verbose = FALSE)    
res <- purrr::map2_lgl(c, d, function(x, y) identical(attr(x, "types"), attr(y, "types")))

process_tokens_maier(settings[[3]], does_tokens)


## settings[!res]

## which(!res)

## length(featnames(a[[2]]))
## length(featnames(b[[2]]))
## setdiff(featnames(b[[2]]), featnames(a[[2]]))

## tmmv.lemmatize_words("much")

## "much" %in% stopwords("english")
## "can" %in% stopwords("english")
## "have" %in% stopwords("english")

setdiff(attr(a[[2]], "type"), attr(b[[2]], "type"))
