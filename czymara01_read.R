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

data_priv <- input[ which(input$OF01_01 != "") | which(input$OF01_01 != " "), ]

corpus_priv <- corpus(as.character(data_priv$OF01_01),
                      docvars = data.frame(gender = data_priv$gender,
                                           id = data_priv$CASE))

german_model <- udpipe_load_model(file = here::here("rawdata/german-gsd-ud-2.5-191206.udpipe"))

parsed_content <- udpipe_annotate(german_model, corpus_priv)

parsed_content_df <- as.data.frame(parsed_content)
