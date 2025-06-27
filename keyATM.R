library(quanteda)
library(keyATM)

## un_corpus <- readRDS("data/un_corpus.RDS")

un_dict_list <- list(
    SDG10 = c("inequality", "inequalities", "income inequality", "wealth distribution", "social inclusion", "equal opportunity", "equal opportunities", "discrimination", "economic divide", "equity"),
    SDG13 = c("climate change", "global warming", "greenhouse gas", "emissions", "carbon dioxide", "climate action", "climate resilience", "climate mitigation")
)

un_dict <- dictionary(un_dict_list)

## testing <- corpus(c("Income inequality is severe", "global warming is real"))

## just for testing
## un_corpus %>% tokens(concatenator = " ", remove_punct = TRUE, remove_symbols = TRUE, remove_numbers = TRUE, split_hyphens = TRUE) -> toks

## saveRDS(toks, "data/toks.RDS")
## ## lemmatize

## lapply(as.list(toks), textstem::lemmatize_words)  %>% as.tokens %>% saveRDS("data/toks_lemmatized.RDS")




un_dfm <- readRDS("data/toks.RDS") %>% tokens_compound(phrase(un_dict)) %>% dfm

un_dfm_lemmatized <- readRDS("data/toks_lemmatized.RDS") %>% tokens_compound(phrase(un_dict)) %>% dfm

condits <- expand.grid(lemmatize = c(TRUE, FALSE), stop = c(TRUE, FALSE), trim = c(TRUE, FALSE), niters = c(100, 300, 500), extra_ntopics = c(0, 10, 20, 50))

saveRDS(condits, "data/keyATM_condits.RDS")

set.seed(721831)

for (i in seq_len(nrow(condits))) {
    print(paste0(i, "/", nrow(condits)))
    if (condits$lemmatize[i]) {
        x <- un_dfm_lemmatized
    } else {
        x <- un_dfm
    }
    if (condits$stop[i]) {
        x %>% dfm_remove(stopwords()) -> x
    }

    if (condits$trim[i]) {
        x %>% dfm_trim(min_docfreq = 0.005, max_docfreq = 0.99, docfreq_type = "prop") -> x
    }

    mod <- x %>% keyATM_read %>% keyATM(model = "base", no_keyword_topics = condits$extra_ntopics[i], keywords = un_dict_list, options = list(iterations = condits$niters[i]))
    saveRDS(mod, paste0("res/keyATM/", i, ".RDS"))
}
