args <- tmmv.parse_args_read(slug = "czymara")
settings <- tmmv.get_settings(full = FALSE, args = args)

library(here)

stopifnot(file.exists(here("rawdata/Corona-Survey_full.dta")))
stopifnot(file.exists(here("rawdata/stopwords-de.txt")))
stopifnot(file.exists(here("rawdata/german-gsd-ud-2.5-191206.udpipe")))

library(quanteda)
library(haven)
library(udpipe)
library(dplyr)
library(stringr)

## foreign::read.dta doesn't work
input <- haven::read_dta(here("rawdata/Corona-Survey_full.dta"))

# NOTE1 we do it here rather than
# https://github.com/czymara/perceiving-COVID19-in-Germany/blob/e18fc33485d6cc50ec0e0f66822a7c4223166805/2.1_topicmodels_gender_03.R#L114C22-L114C61

# NOTE2 To prevent the implicit conversion of factor by stm and weighted lda

# NOTE3 The original code is not sufficient.
# https://github.com/czymara/perceiving-COVID19-in-Germany/blob/e18fc33485d6cc50ec0e0f66822a7c4223166805/2.1_topicmodels_gender_03.R#L71

data_priv <- input |>
    mutate(gender = case_match(DE03,
                               1 ~ "male",
                               2 ~ "female",
                               .default = NA_character_)) |>
    filter(!is.na(gender)) |> ##NOTE1
    mutate(gender = factor(gender, levels = c("male", "female"))) |> #NOTE2
    mutate(OF01_01 = stringr::str_trim(OF01_01)) |>
    filter(OF01_01 != "" &
           !stringr::str_detect(OF01_01, "^[[:space:]]+$")) ##NOTE3
    
corpus_priv <- corpus(as.character(data_priv$OF01_01),
                      docvars = data.frame(gender = data_priv$gender,
                                           id = data_priv$CASE))

german_model <- udpipe_load_model(file = here::here("rawdata/german-gsd-ud-2.5-191206.udpipe"))

parsed_content <- udpipe_annotate(german_model, corpus_priv)

parsed_content_df <- as.data.frame(parsed_content)

## there are some words with more than one lemma
## e.g. sich -> er/es/sie

parsed_content_df |>
    select(lemma) |>
    count(lemma, sort = TRUE) |>
    filter(stringr::str_detect(lemma, "\\|"))

## for "sich", it's better to put to back to "sich"
## it's not always removed as a stopword, choosing one gender can be problematic, given the original research questions
parsed_content_df |>
    select(token, lemma) |>
    filter(lemma == "er|es|sie")

parsed_content_df_fixed <- parsed_content_df

parsed_content_df_fixed$lemma[parsed_content_df_fixed$lemma == "er|es|sie"] <- "sich"

## for other we can just choose the first one
parsed_content_df_fixed[,c("lemma"), drop = FALSE] |>
    count(lemma, sort = TRUE) |>
    filter(stringr::str_detect(lemma, "\\|"))

## NAs are contractions
parsed_content_df_fixed[is.na(parsed_content_df_fixed$lemma), c("token", "lemma")]

parsed_content_df_fixed <- parsed_content_df_fixed[!is.na(parsed_content_df_fixed$lemma),]



parsed_content_df_fixed$lemma[stringr::str_detect(parsed_content_df_fixed$lemma, "\\|")] <-
    purrr::map_chr(
               parsed_content_df_fixed$lemma[
                                           stringr::str_detect(
                                                        parsed_content_df_fixed$lemma, "\\|")],
               \(x) { strsplit(x, "\\|")[[1]][1]}
           )

## all cleaned
parsed_content_df_fixed[,c("lemma"), drop = FALSE] |> count(lemma, sort = TRUE) |> filter(stringr::str_detect(lemma, "\\|"))

parsed_content_df_fixed |>
    group_by(doc_id) |>
    summarize(content = paste(lemma, collapse = " ")) |>
    mutate(doc_id = stringr::str_extract(doc_id, "[0-9]+")) |>
    mutate(doc_id = as.numeric(doc_id)) |>
    arrange(doc_id) -> lemma_df

lemma_corpus_priv <- corpus(lemma_df$content,
                            docvars =
                                data.frame(gender = data_priv$gender,
                                           id = data_priv$CASE))

stopifnot(ndoc(lemma_corpus_priv) == ndoc(corpus_priv))

## santity check

for (i in sample(1:ndoc(corpus_priv), 30)) {
    print(corpus_priv[i])
    print(lemma_corpus_priv[i])
}

rm(parsed_content_df_fixed, parsed_content_df, parsed_content)

toks_priv <- tokens(corpus_priv, remove_punct = TRUE,
                    remove_numbers = TRUE,
                    remove_symbols = TRUE,
                    remove_separators = TRUE,
                    split_hyphens = TRUE,
                    remove_url = TRUE,
                    include_docvars = TRUE)

lemma_toks_priv <- tokens(lemma_corpus_priv, remove_punct = TRUE,
                          remove_numbers = TRUE,
                          remove_symbols = TRUE,
                          remove_separators = TRUE,
                          split_hyphens = TRUE,
                          remove_url = TRUE,
                          include_docvars = TRUE)

current_tokens_list<- list()
current_tokens_list[["normal"]] <- toks_priv
current_tokens_list[["lemmatized"]] <- lemma_toks_priv

stopwords_de <- read.table(here("rawdata/stopwords-de.txt"), encoding = "UTF-8", colClasses=c("character"))$V1
all_stopwords <- c(stopwords_de, stopwords("german"))


## The data is not that big; we don't need that

## if (args$debug) {
##     set.seed(1233)
##     current_tokens_list <- purrr::map(current_tokens_list, tokens_sample, size = 300)
##     cat("DEBUG: Only 300 documents are selected \n")
## }

process_tokens <- function(setting, current_tokens_list, all_stopwords, args) {
    ## print(setting)
    verbose <- args$debug
    if (setting$token_normalization == "lemmatization") {
        current_tokens <- current_tokens_list[["lemmatized"]]
    } else {
        current_tokens <- current_tokens_list[["normal"]]
    }
    if (setting$stopword_removal) {
        current_tokens <- current_tokens |>
            tokens_remove(all_stopwords,
                          case_insensitive = TRUE, 
                          padding = FALSE,
                          verbose = verbose)
    }
    if (setting$token_normalization == "stemming") {
        current_tokens <- tokens_wordstem(current_tokens, language = "german")
    }
    current_dfm <- dfm(current_tokens)
    if (setting$trimming) {
        # We respect the original trimming scheme:
        ## https://github.com/czymara/perceiving-COVID19-in-Germany/blob/e18fc33485d6cc50ec0e0f66822a7c4223166805/2.1_topicmodels_gender_03.R#L107
        current_dfm <- dfm_trim(current_dfm, max_docfreq = 0.20,  min_docfreq = 0.001, docfreq_type = "prop")
    }
    current_hash <- rlang::hash(setting)
    ##print(current_hash)
    saveRDS(current_dfm, here(args$output_dir, paste0(current_hash, ".RDS")))
    gc()
    invisible(NULL)
}

purrr::walk(settings,
            process_tokens,
            current_tokens_list = current_tokens_list,
            all_stopwords = all_stopwords,
            args = args,
            .progress = !args$debug)

if (args$debug) {
    library(testthat)
    for (setting in settings) {
        ## print(setting)
        output_dir <- args$output_dir
        filename <- paste0(rlang::hash(setting), ".RDS")
        testthat::expect_true(file.exists(here(output_dir, filename)))
        current_dfm <- readRDS(here(output_dir, filename))
        features <- featnames(current_dfm)
        if (setting$token_normalization == "none") {
            testthat::expect_true("ähnliches" %in% features)
        }
        if (setting$token_normalization == "lemmatization") {
            testthat::expect_false("ähnliches" %in% features)
            testthat::expect_true("ähnlich" %in% features)
        }
        if (setting$token_normalization == "stemming") {
            testthat::expect_true("interess" %in% features)
        }
        if (setting$stopword_removal) {
            testthat::expect_false(all(purrr::map_lgl(all_stopwords, ~. %in% features)))
        } else {
            testthat::expect_true(any(purrr::map_lgl(all_stopwords, ~. %in% features)))
        }
        if (setting$trimming) {
            testthat::expect_true(topfeatures(current_dfm, scheme = "docfreq", n = 1) <= ndoc(current_dfm) * 0.2)
        } else {
            testthat::expect_false(topfeatures(current_dfm, scheme = "docfreq", n = 1) <= ndoc(current_dfm) * 0.2)
        }    
    }
}
