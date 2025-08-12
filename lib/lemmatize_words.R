#' A replacement of textstem::lemmatize_words
#' Modified from Rinker TW (2018). textstem: Tools for stemming and lemmatizing text. version 0.1.4, http://github.com/trinker/textstem.
#' Original License: GPL-2
tmmv.lemmatize_words <- function(tokens) {
    token_matches <- match(tokens, lexicon::hash_lemmas[[1]])
    tokens[!is.na(token_matches)] <- lexicon::hash_lemmas[
        token_matches[!is.na(token_matches)],
    ][[2]]
    return(tokens)
}
