#' our base-only replacement of readtext::read_text
#' note that input_path is not a glob
tmmv.read_text_base <- function(input_path, dvsep, docvarnames) {
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

#' A replacement of textstem::lemmatize_words
tmmv.lemmatize_words <- function(tokens) {
    token_matches <- match(tokens, lexicon::hash_lemmas[[1]])
    tokens[!is.na(token_matches)] <- lexicon::hash_lemmas[
        token_matches[!is.na(token_matches)],
    ][[2]]
    return(tokens)
}

tmmv.parse_args <- function(args = commandArgs()) {
    output <- list()
    output$debug <- "--debug" %in% args
    args <- setdiff(args, "--debug")
    args_index <- which(args == "--args")
    if (identical(args_index, integer(0))) {
        output$args <- NULL
    } else {
        if (args_index[1] == length(args)) {
            output$args <- NULL
        } else {
            output$args <- args[seq(args_index+1,
                                    length(args))]
        }
    }
    filearg <- grep("--file=", args, value = TRUE)[1]
    output$filename <- gsub("--file=", "", filearg)
    return(output)
}

tmmv.parse_args_read <- function(slug = "chan") {
    args <- tmmv.parse_args()
    args$slug <- slug
    if (!args$debug) {
        args$output_dir <- paste0("intermediate/", slug)
        return(args)
    }
    args$output_dir <- paste0("debug/", slug)
    unlink(args$output_dir, recursive = TRUE, force = TRUE)
    dir.create(args$output_dir, recursive = TRUE, showWarnings = FALSE)
    cat("DEBUG MODE ENABLED. Please check the artefacts in",
        args$output_dir,
        "\n")
    return(args)
}

tmmv.parse_args_train <- function(slug = "chan") {
    args <- tmmv.parse_args()
    args$slug <- slug    
    if (!args$debug && is.null(args$arg)) {
        msg <- paste("You must provide the current run number, e.g. Rscript",
                     args$filename,
                     "1")
        stop(msg, call. = FALSE)
    }
    if (!args$debug) {
        args$current_run <- args$args[1]
        args$prefix <- "intermediate"
    } else {
        args$current_run <- "1"
        args$prefix <- "debug"
        output_display <- paste0(args$prefix, "/1/", slug, "/1")
        cat("DEBUG MODE ENABLED. Please check the artefacts in",
            output_display,
            "\n")
        unlink(here::here(args$prefix, slug, args$current_run), recursive = TRUE, force = TRUE)
    }
    args$output_dir <- here::here(args$prefix, slug, args$current_run)
    dir.create(args$output_dir, recursive = TRUE, showWarnings = FALSE)
    stopifnot(dir.exists(args$output_dir))
    return(args)
}
