library(readtext)
library(quanteda)
library(stringr)
# library(textstem) don't import it, but use it here
library(here)


## Modified from the original RMD file

ungd_files <- readtext(here("rawdata/un/TXT/*"), 
                                 docvarsfrom = "filenames", 
                                 dvsep="_", 
                                 docvarnames = c("Country", "Session", "Year"))

ungd_files$doc_id <- str_replace(ungd_files$doc_id , ".txt", "") |>
    str_replace("_\\d{2}", "")

ungd_corpus <- corpus(ungd_files, text_field = "text") 

## Removed the stopword removal
tokens <- tokens(ungd_corpus, what = "word",
                 remove_punct = TRUE,
                 remove_symbols = TRUE,
                 remove_numbers = TRUE,
                 remove_url = TRUE,
                 split_hyphens = FALSE,
                 verbose = TRUE) |>
    tokens_tolower()


# combis
# col1: 1,2,3 = no unit, lemmatize, stem
# col2: 1,0 = stopword yes no
# col3: 1,0 = trim yes no
combis <- expand.grid(c(1,2,3), c(1, 0), c(1, 0)) |> as.matrix()
attr(combis, "dimnames") <- NULL

## Stupid but we only do it once

for (i in seq_len(nrow(combis))) {
    print(i)
    if (combis[i, 2] == 1) {
        temp_tokens <- tokens |>
            tokens_select(stopwords("english"), selection = "remove",
                          padding = FALSE, verbose = TRUE)
    } else {
        temp_tokens <- tokens
    }
    ## This tokens_select is kind of unreasonable, but let's keep it
    temp_tokens <- temp_tokens |>
        tokens_select(c("[\\d-]", "[[:punct:]]", "^.{1}$", "us",
                        "united_nations", "united", "nations"),
                      selection = "remove", 
                      valuetype="regex", 
                      min_nchar = 2L,
                      verbose = TRUE)
    if (combis[i,1] == 2) {
        ori_types <- attr(temp_tokens, "types")
        lemma_types <- textstem::lemmatize_words(ori_types)
        temp_tokens <- tokens_replace(temp_tokens, ori_types, lemma_types,
                                      valuetype = "fixed")
    }
    if (combis[i,1] == 3) {
        temp_tokens <- tokens_wordstem(temp_tokens)
    }
    temp_dfm <- temp_tokens |>
        tokens_select(min_nchar = 2) |>
        tokens_ngrams(n = 1:2) |> dfm()
    if (combis[i,3] == 1) {
        temp_dfm <- temp_dfm |>
            dfm_trim(min_docfreq = 0.005, max_docfreq = 0.5,
                     docfreq_type = "prop", verbose = TRUE)
    }
    current_hash <- rlang::hash(combis[i, 1:3])
    print(current_hash)
    saveRDS(temp_dfm, here("intermediate/un/", paste0(current_hash, ".RDS")))
    ## thank you for your 16G of ram
    rm(temp_dfm, temp_tokens)
    gc()
}
