library(quanteda)

un_corpus <- readRDS("data/un_corpus.RDS")
un_corpus %>% tokens(concatenator = " ", remove_punct = TRUE, remove_symbols = TRUE, remove_numbers = TRUE, split_hyphens = TRUE) %>% saveRDS("data/toks.RDS")
## lemmatize

toks <- readRDS("data/toks.RDS")
type <- attr(toks, "types")
attr(toks, "type") <- textstem::lemmatize_words(type)
quanteda:::tokens_recompile(toks) %>% tokens(concatenator = " ", remove_punct = TRUE, remove_symbols = TRUE, remove_numbers = TRUE, split_hyphens = TRUE) %>%  saveRDS("data/toks_lemmatized.RDS")
