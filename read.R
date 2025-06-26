library(readtext)
library(quanteda)

un_corpus <- readtext::readtext("data/TXT") %>% corpus
docvars(un_corpus, "year") <- as.numeric(str_split(docnames(un_corpus), "[_\\.]", n = 4, simplify = TRUE)[,3])
saveRDS(un_corpus, "data/un_corpus.RDS")
