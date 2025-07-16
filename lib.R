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
