#' our base-only replacement of readtext::read_text
#' note that input_path is not a glob
read_text_base <- function(input_path, dvsep, docvarnames) {
    txt_files <- list.files(input_path, recursive = TRUE)
    txt_content <- vapply(txt_files,
                          function(x) paste(suppressWarnings(readLines(file.path(input_path, x))),
                                            collapse = "\n"),
                          character(1))
    output <- data.frame(text = txt_content, stringsAsFactors = FALSE)
    output$doc_id <- basename(txt_files)
    meta <- strsplit(tools::file_path_sans_ext(output$doc_id), dvsep, fixed = TRUE)
    
    meta_df <- as.data.frame(do.call(rbind, meta))
    colnames(meta_df) <- docvarnames
    meta_df <- lapply(meta_df, function(x) type.convert(as.character(x), as.is = TRUE))
    meta_df <- data.frame(meta_df, stringsAsFactors = FALSE)
    output <- cbind(output, meta_df)
    return(output)
}

## To prove that the corpora produced are functionally the same (except all the quanteda metadata)

## x <- quanteda::corpus(read_text_base(here::here("rawdata/jankin/TXT/"),
##                                      dvsep = "_", 
##                                      docvarnames = c("Country", "Session", "Year")))

## ungd_files <- readtext::readtext(here::here("rawdata/jankin/TXT/*"), 
##                                  docvarsfrom = "filenames", 
##                                  dvsep="_", 
##                                  docvarnames = c("Country", "Session", "Year"))
## y <- quanteda::corpus(ungd_files)

## for (i in sample(seq_len(quanteda::ndoc(x)), 100)) {
##     testthat::expect_equal(x[i], y[i])
## }


#' A replacement of textstem::lemmatize_words
lemmatize_words <- function(tokens) {
    token_matches <- match(tokens, lexicon::hash_lemmas[[1]])
    tokens[!is.na(token_matches)] <- lexicon::hash_lemmas[
        token_matches[!is.na(token_matches)],
    ][[2]]
    return(tokens)
}

## To prove that the lemmatizations are the same

## ungd_files <- readtext::readtext(
##     here::here("rawdata/jankin/TXT/"),
##     dvsep = "_",
##     docvarnames = c("Country", "Session", "Year")
## )

## ungd_files$doc_id <- stringr::str_replace(ungd_files$doc_id, ".txt", "") |>
##     stringr::str_replace("_\\d{2}", "")

## ungd_corpus <- quanteda::corpus(ungd_files, text_field = "text")

## ungd_tokens <- quanteda::tokens(
##     ungd_corpus,
##     what = "word",
##     remove_punct = TRUE,
##     remove_symbols = TRUE,
##     remove_numbers = TRUE,
##     remove_url = TRUE,
##     split_hyphens = FALSE,
##     verbose = TRUE
## ) |>
##     quanteda::tokens_tolower()

## ori_types <- attr(ungd_tokens, "types")
## textstem_lemmatized <- textstem::lemmatize_words(ori_types)
## our_lemmatized  <- lemmatize_words(ori_types)

## testthat::expect_identical(textstem_lemmatized, our_lemmatized)
