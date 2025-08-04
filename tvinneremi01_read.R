## the data is corrupted due to file encoding issues

library(here)
library(readr)
library(quanteda)
library(udpipe)
library(dplyr)


input <- iconv(readLines(here("rawdata", "ncp-stm-data.csv")),
               from = "latin1", to = "UTF-8") |>
    paste(collapse = "\n") |>
    readr::read_delim(delim = ";", show_col_types = FALSE) |>
    na.omit()

original_corpus <- corpus(input, text_field = "openanswer")

norwegian_model <- udpipe_load_model(file = here::here("rawdata/norwegian-bokmaal-ud-2.5-191206.udpipe"))

parsed_content <- udpipe_annotate(norwegian_model, original_corpus)
parsed_content_df <- as.data.frame(parsed_content)

## no need to do any selection (like German or Italian)
## no multilemma words, no contractions

parsed_content_df_fixed <- parsed_content_df

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

## Need to reference a really old version of stm
## https://github.com/cran/stm/tree/140d5f4b8a46bc069880e1e1feeb432f02199

## original process is using stm (pre 1.0)

## processed <- textProcessor(data$openanswer, metadata=data, language="norwegian", verbose=TRUE)

## out <- prepDocuments(processed$documents, processed$vocab, processed$meta,
##                      lower.thresh=5)

## by default, the order is: remove white space, lower case, stopwords, numbers, punctuation, stem
## lower.thresh is docfreq (inclusive),
## i.e. lower.thresh = 5 will also remove those with docfreq == 5

