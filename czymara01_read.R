library(here)
library(quanteda)

## foreign::read.dta doesn't work


input <- haven::read_dta(here("rawdata/Corona-Survey_full.dta"))

## The lost art of doing data manipulation with base
input$gender <- NA
input$gender[input$DE03 == 1] <- "male"
input$gender[input$DE03 == 2] <- "female"

data_priv <- input[ which(input$OF01_01 != ""), ]

corpus_priv <- corpus(as.character(data_priv$OF01_01),
                      docvars = data.frame(gender = data_priv$gender,
                                           id = data_priv$CASE))

