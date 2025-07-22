library(here)
library(quanteda)
library(haven)
library(udpipe)
## foreign::read.dta doesn't work
input <- haven::read_dta(here("rawdata/Corona-Survey_full.dta"))

## The lost art of doing data manipulation with base
input$gender <- NA
input$gender[input$DE03 == 1] <- "male"
input$gender[input$DE03 == 2] <- "female"

data_priv <- input[input$OF01_01 != "" & input$OF01_01 != " ", ]

corpus_priv <- corpus(as.character(data_priv$OF01_01),
                      docvars = data.frame(gender = data_priv$gender,
                                           id = data_priv$CASE))

german_model <- udpipe_load_model(file = here::here("rawdata/german-gsd-ud-2.5-191206.udpipe"))

parsed_content <- udpipe_annotate(german_model, corpus_priv)

parsed_content_df <- as.data.frame(parsed_content)

## there are some words with more than one lemma
## e.g. sich -> er/es/sie
library(dplyr)
parsed_content_df[,c("lemma"), drop = FALSE] |> count(lemma, sort = TRUE) |> filter(stringr::str_detect(lemma, "\\|"))

## for "sich", it's better to put to back to "sich"
## it's not always removed as a stopword, choosing one gender can be problematic, given the original research questions
parsed_content_df |> select(token, lemma) |> filter(lemma == "er|es|sie")

parsed_content_df_fixed <- parsed_content_df

parsed_content_df_fixed$lemma[parsed_content_df_fixed$lemma == "er|es|sie"] <- "sich"

## for other we can just choose the first one
parsed_content_df_fixed[,c("lemma"), drop = FALSE] |> count(lemma, sort = TRUE) |> filter(stringr::str_detect(lemma, "\\|"))

get_first <- function(x) {
    strsplit(x, "\\|")[[1]][1]
}

## contractions
parsed_content_df_fixed[is.na(parsed_content_df_fixed$lemma), c("token", "lemma")]

parsed_content_df_fixed <- parsed_content_df_fixed[!is.na(parsed_content_df_fixed$lemma),]

parsed_content_df_fixed$lemma[stringr::str_detect(parsed_content_df_fixed$lemma, "\\|")] <- purrr::map_chr(parsed_content_df_fixed$lemma[stringr::str_detect(parsed_content_df_fixed$lemma, "\\|")], get_first)

parsed_content_df_fixed[,c("lemma"), drop = FALSE] |> count(lemma, sort = TRUE) |> filter(stringr::str_detect(lemma, "\\|"))

parsed_content_df_fixed |> group_by(doc_id) |> summarize(content = paste(lemma, collapse = " ")) |> mutate(doc_id = stringr::str_extract(doc_id, "[0-9]+")) |> mutate(doc_id = as.numeric(doc_id)) |> arrange(doc_id) -> lemma_df

lemma_corpus_priv <- corpus(lemma_df$content,
                            docvars = data.frame(gender = data_priv$gender,
                                                 id = data_priv$CASE))

setdiff(1:1137, lemma_df$doc_id)

corpus_priv[759]
