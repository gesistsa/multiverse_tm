args <- tmmv.parse_args_read(slug = "curini")
settings <- tmmv.get_settings(full = FALSE, args = args)

library(here)
library(quanteda)
library(udpipe)

myText <- tmmv.read_text_base(here("rawdata/zip_texts.rar"),
                              dvsep = "_", docvarnames = c("Party", "Mission"))

myText$doc_id <- gsub(".txt", "", myText$doc_id)


myText$text <- gsub("[\u0092]","'",myText$text)
myText$text <- gsub("[\u2019]","'",myText$text)
myText$text <- gsub("[\u00b4]","'",myText$text)
myText$text <- gsub("[\u00d5]","'",myText$text)
myText$text <- gsub("[\u017e]","'",myText$text)
myText$text <- gsub("[\u017d]","'",myText$text)
myText$text <- gsub("[\u02c6]","'",myText$text)
myText$text <- gsub("[\u00ca]","'",myText$text)
myText$text <- gsub("[\u02dc]","'",myText$text)
myText$text <- gsub("[\u00c7]","'",myText$text)
myText$text <- gsub("'"," ",myText$text)

myText$text <- gsub("�no�","no",myText$text)
myText$text <-  gsub("�no�","no",myText$text)
myText$text <-  gsub("�No�","no",myText$text)


meta.pr <- read.table(here("rawdata", "meta_table.tab"), header = TRUE)

meta.pr$Name <- as.character(meta.pr$Name )
meta.pr <- meta.pr[,-2]
names(meta.pr)[4] <- "Mission_name"

fit <- merge(myText, meta.pr, by.x = "doc_id", by.y = "Name")

colnames(fit)[colnames(fit) == "Left_right_CHES"] <- "LR"

fit$Party <- as.factor(fit$Party)
fit$Mission <-as.factor(fit$Mission)


original_corpus <- corpus(fit)

italian_model <- udpipe_load_model(file = here::here("rawdata/italian-isdt-ud-2.5-191206.udpipe"))

parsed_content <- udpipe_annotate(italian_model, original_corpus)
parsed_content_df <- as.data.frame(parsed_content)
library(dplyr)

## Unlike czymara, we can safely select the first lemma

## parsed_content_df |>
##     select(lemma) |>
##     count(lemma, sort = TRUE) |>
##     filter(stringr::str_detect(lemma, "\\|"))

parsed_content_df_fixed <- parsed_content_df

parsed_content_df_fixed[,c("lemma"), drop = FALSE] |>
    count(lemma, sort = TRUE) |>
    filter(stringr::str_detect(lemma, "\\|"))

## contractions
parsed_content_df_fixed[is.na(parsed_content_df_fixed$lemma), c("token", "lemma")]

parsed_content_df_fixed <- parsed_content_df_fixed[!is.na(parsed_content_df_fixed$lemma),]

parsed_content_df_fixed$lemma[stringr::str_detect(parsed_content_df_fixed$lemma, "\\|")] <-
    purrr::map_chr(
               parsed_content_df_fixed$lemma[
                                           stringr::str_detect(
                                                        parsed_content_df_fixed$lemma, "\\|")],
               \(x) { strsplit(x, "\\|")[[1]][1]}
           )

parsed_content_df_fixed[,c("lemma"), drop = FALSE] |> count(lemma, sort = TRUE) |> filter(stringr::str_detect(lemma, "\\|"))

parsed_content_df_fixed |>
    group_by(doc_id) |>
    summarize(content = paste(lemma, collapse = " ")) |>
    mutate(doc_id = stringr::str_extract(doc_id, "[0-9]+")) |>
    mutate(doc_id = as.numeric(doc_id)) |>
    arrange(doc_id) -> lemma_df

lemma_corpus <- corpus(lemma_df$content)
docvars(lemma_corpus) <- docvars(original_corpus)
docnames(lemma_corpus) <- docnames(original_corpus)

stopifnot(ndoc(lemma_corpus) == ndoc(original_corpus))

## sanity check

for (i in sample(1:ndoc(original_corpus), 30)) {
    print(original_corpus[i])
    print(lemma_corpus[i])
}

rm(parsed_content_df_fixed, parsed_content_df, parsed_content)

## original process is in dfm (pre quanteda 2.0)
## 

## myDfm <- dfm(corpus, remove = c(stopwords("italian"), "l", "d", "dell", "dall", "afganistan", "libano", "kosovo", "iraq", "libia", "albania")
## , tolower = TRUE, stem = TRUE, remove_punct = TRUE, remove_numbers=TRUE)


original_toks <- tokens(original_corpus, remove_punct = TRUE,
                        remove_numbers = TRUE, include_docvars = TRUE)

lemma_toks <- tokens(lemma_corpus, remove_punct = TRUE,
                     remove_numbers = TRUE, include_docvars = TRUE)

current_tokens_list<- list()
current_tokens_list[["normal"]] <- original_toks
current_tokens_list[["lemmatized"]] <- lemma_toks

## from the original code

all_stopwords <- c(stopwords("italian"), "l", "d", "dell", "dall", "afganistan", "libano", "kosovo", "iraq", "libia", "albania")

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
        current_tokens <- tokens_wordstem(current_tokens, language = "italian")
    }
    current_dfm <- dfm(current_tokens)
    if (setting$trimming) {
        ## default trimming
        current_dfm <- dfm_trim(current_dfm, max_docfreq = 0.5,  min_docfreq = 0.005, docfreq_type = "prop")
    }
    current_hash <- rlang::hash(setting)
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
            ## plural of "afghano" (male person from Afghanistan)
            testthat::expect_true("afghani" %in% features)
        }
        if (setting$token_normalization == "lemmatization") {
            testthat::expect_false("afghani" %in% features)
            testthat::expect_true("afghano" %in% features)
        }
        if (setting$token_normalization == "stemming") {
            testthat::expect_false("afghani" %in% features)
            testthat::expect_true("afghan" %in% features)
        }
        if (setting$stopword_removal) {
            testthat::expect_false(all(purrr::map_lgl(all_stopwords, ~. %in% features)))
        } else {
            testthat::expect_true(any(purrr::map_lgl(all_stopwords, ~. %in% features)))
        }

        if (setting$trimming) {
            testthat::expect_true(topfeatures(current_dfm, scheme = "docfreq", n = 1) <= 150)
        } else {
            testthat::expect_true(topfeatures(current_dfm, scheme = "docfreq", n = 1) > ndoc(lemma_corpus) / 2)
        }
    }
}
