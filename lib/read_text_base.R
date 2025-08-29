#' our base-only replacement of readtext::read_text
#' note that input_path is not a glob
#' modified from Benoit K, Obeng A (2025). readtext: Import and Handling for Plain and Formatted Text Files_. https://doi.org/10.32614/CRAN.package.readtext>
#' R package version 0.92.1, <https://CRAN.R-project.org/package=readtext>.
#' Original license: GPL-3

tmmv.read_text_base <- function(input_path, dvsep, docvarnames) {
    if (fs::dir_exists(input_path)) {
        txt_files <- fs::dir_ls(input_path, recurse = TRUE, type = "file")
        txt_content <- vapply(
            txt_files,
            function(x) {
                paste(
                    suppressWarnings(readLines(x)),
                    collapse = "\n"
                )
            },
            character(1)
        )
    } else {
        ## assume to be an archive
        txt_files <- archive::archive(input_path)$path
        txt_content <- vapply(
            txt_files,
            function(x) {
                paste(
                    suppressWarnings(readLines(
                        archive::archive_read(archive = input_path, file = x)
                    )),
                    collapse = "\n"
                )
            },
            character(1)
        )
    }

    output <- data.frame(text = txt_content, stringsAsFactors = FALSE)
    output$doc_id <- basename(txt_files)

    meta <- strsplit(
        tools::file_path_sans_ext(output$doc_id),
        dvsep,
        fixed = TRUE
    )

    meta_df <- as.data.frame(do.call(rbind, meta))
    colnames(meta_df) <- docvarnames
    meta_df <- lapply(meta_df, function(x) {
        type.convert(as.character(x), as.is = TRUE)
    })
    meta_df <- data.frame(meta_df, stringsAsFactors = FALSE)
    output <- cbind(output, meta_df)
    return(output)
}
