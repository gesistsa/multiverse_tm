#' return missing keywords topics
#' modified from:  Eshima S, Imai K, Sasaki T (2024). "Keyword-Assisted Topic Models." American Journal of Political Science_, 68(2), 730-750.
#' https://doi.org/10.1111/ajps.12779>.
#' version 0.5.3
#' Original license: GPL-3
tmmv.check_keywords <- function(docs, keywords) {
    if (is.null(docs$wd_names)) {
        unique_words <- unique(unlist(
            docs$W_raw,
            use.names = FALSE,
            recursive = FALSE
        ))
        keyATM:::check_vocabulary(wd_names)
    } else {
        unique_words <- docs$wd_names
    }
    # Prune keywords that do not appear in the corpus
    keywords_flat <- unlist(keywords, use.names = FALSE, recursive = FALSE)
    non_existent <- keywords_flat[!keywords_flat %in% unique_words]
    keywords <- lapply(keywords, function(x) {
        x[!x %in% non_existent]
    })
    # Check there is at least one keywords in each topic
    num_keywords <- unlist(lapply(keywords, length))
    check_zero <- which(as.vector(num_keywords) != 0)
    return(check_zero)
}
