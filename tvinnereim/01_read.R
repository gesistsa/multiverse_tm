args <- tmmv.parse_args_read(slug = "tvinnereim")
settings <- tmmv.get_settings(full = FALSE, args = args)

library(here)
library(readr)
library(quanteda)
library(udpipe)
library(dplyr)

## the data is corrupted due to file encoding issues

input <- iconv(
    readLines(here("rawdata", "ncp-stm-data.csv")),
    from = "latin1",
    to = "UTF-8"
) |>
    paste(collapse = "\n") |>
    readr::read_delim(delim = ";", show_col_types = FALSE) |>
    na.omit()

original_corpus <- corpus(input, text_field = "openanswer")

norwegian_model <- udpipe_load_model(
    file = here::here("rawdata/norwegian-bokmaal-ud-2.1-20180111.udpipe")
)

parsed_content <- udpipe_annotate(norwegian_model, original_corpus)
parsed_content_df <- as.data.frame(parsed_content)

## no need to do any selection (like German or Italian)
## no multilemma words, no contractions

parsed_content_df_fixed <- parsed_content_df

parsed_content_df_fixed |>
    group_by(doc_id) |>
    summarize(content = paste(lemma, collapse = " ")) |>
    mutate(doc_id = stringr::str_extract(doc_id, "[0-9]+")) |>
    mutate(doc_id = as.numeric(doc_id)) |>
    arrange(doc_id) -> lemma_df

lemma_corpus <- corpus(lemma_df$content)
docvars(lemma_corpus) <- docvars(original_corpus)
docnames(lemma_corpus) <- docnames(original_corpus)

stopifnot(ndoc(lemma_corpus) == ndoc(original_corpus))

## sanity check

for (i in sample(1:ndoc(original_corpus), 30)) {
    print(original_corpus[i])
    print(lemma_corpus[i])
}

rm(parsed_content_df_fixed, parsed_content_df, parsed_content)

## Need to reference a really old version of stm
## https://github.com/cran/stm/tree/140d5f4b8a46bc069880e1e1feeb432f02199

## original process is using stm (pre 1.0)

## processed <- textProcessor(data$openanswer, metadata=data, language="norwegian", verbose=TRUE)

## out <- prepDocuments(processed$documents, processed$vocab, processed$meta,
##                      lower.thresh=5)

## by default, the order is: remove white space, lower case, stopwords, numbers, punctuation, stem
## lower.thresh is docfreq (inclusive),
## i.e. lower.thresh = 5 will also remove those with docfreq == 5
## which is not the same as dfm(min_docfreq = 5) (not inclusive); need to increase it to 6

## quanteda::stopwords("norwegian") is the same as tm::stopwords("norwegian")

original_toks <- tokens(
    original_corpus,
    remove_punct = TRUE,
    remove_numbers = TRUE,
    include_docvars = TRUE
)

## the lemmatizer left $ before puntuation. Need to remove it explicitly
lemma_toks <- tokens(
    lemma_corpus,
    remove_punct = TRUE,
    remove_numbers = TRUE,
    include_docvars = TRUE
) |>
    tokens_remove("$", valuetype = "fixed")

## Keep the original so-called "pre stemming" (very error prone, but we respect the original authors)

do_pre_stemming <- function(oa) {
    for (i in 1:length(oa)) {
        oa[[i]] <- gsub("frem", "fram", oa[[i]])
        oa[[i]] <- gsub("forurensing", "forurens", oa[[i]])
        oa[[i]] <- gsub("forurensning", "forurens", oa[[i]])
        oa[[i]] <- gsub("smelting", "smelt", oa[[i]])
        oa[[i]] <- gsub("altid", "alltid", oa[[i]])
        oa[[i]] <- gsub("arktisk", "arktis", oa[[i]])
        oa[[i]] <- gsub("bekymring", "bekymr", oa[[i]])
        oa[[i]] <- gsub("bekymringsfullt", "bekymr", oa[[i]])
        oa[[i]] <- gsub("betydning", "bety", oa[[i]])
        oa[[i]] <- gsub("betyr", "bety", oa[[i]])
        oa[[i]] <- gsub("død", "dø", oa[[i]])
        oa[[i]] <- gsub("dør", "dø", oa[[i]])
        #  oa[[i]] <- gsub("endring", "endr", oa[[i]])
        oa[[i]] <- gsub("enkelt", "enkel", oa[[i]])
        oa[[i]] <- gsub("ekstremt", "ekstrem", oa[[i]])
        oa[[i]] <- gsub("extrem", "ekstrem", oa[[i]])
        oa[[i]] <- gsub("fleir", "fler", oa[[i]])
        oa[[i]] <- gsub("flomm", "flom", oa[[i]])
        oa[[i]] <- gsub("flomr", "flom", oa[[i]])
        oa[[i]] <- gsub("forandring", "forandr", oa[[i]])
        oa[[i]] <- gsub("fosilt", "fossil", oa[[i]])
        oa[[i]] <- gsub("fossilt", "fossil", oa[[i]])
        oa[[i]] <- gsub("fremtid", "framtid", oa[[i]])
        oa[[i]] <- gsub("globaloppvarming", "global oppvarming", oa[[i]])
        oa[[i]] <- gsub("godt", "god", oa[[i]])
        oa[[i]] <- gsub("høgar", "høy", oa[[i]])
        oa[[i]] <- gsub("høyer", "høy", oa[[i]])
        oa[[i]] <- gsub("høyt", "høy", oa[[i]])
        oa[[i]] <- gsub("konsekvens", "konsekv", oa[[i]])
        oa[[i]] <- gsub("langt", "lang", oa[[i]])
        oa[[i]] <- gsub("laver", "lav", oa[[i]])
        oa[[i]] <- gsub("lavt", "lav", oa[[i]])
        oa[[i]] <- gsub("meir", "mer", oa[[i]])
        # oa[[i]] <- gsub("menneskeskapt", "menneskeskap", oa[[i]])
        # oa[[i]] <- gsub("menneske", "mennesk", oa[[i]])
        oa[[i]] <- gsub("overdrevent", "overdriv", oa[[i]])
        oa[[i]] <- gsub("overdrev", "overdriv", oa[[i]])
        oa[[i]] <- gsub("oson", "ozon", oa[[i]])
        oa[[i]] <- gsub("ozonlag", "ozon", oa[[i]])
        oa[[i]] <- gsub("politikern", "politiker", oa[[i]])
        oa[[i]] <- gsub("reell", "reel", oa[[i]])
        oa[[i]] <- gsub("reelt", "reel", oa[[i]])
        oa[[i]] <- gsub("somr", "sommer", oa[[i]]) # exception: shorter to longer
        oa[[i]] <- gsub("teknologisk", "teknologi", oa[[i]])
        oa[[i]] <- gsub("temperaturendr", "temperaturforandr", oa[[i]])
        oa[[i]] <- gsub("temperaturøkning", "temperaturstigning", oa[[i]])
        oa[[i]] <- gsub("tempratur", "temperatur", oa[[i]]) # mis-spelling
        oa[[i]] <- gsub("usikker", "usikk", oa[[i]])
        oa[[i]] <- gsub("ustabilt", "ustabil", oa[[i]])
        oa[[i]] <- gsub("utrydning", "utrydd", oa[[i]])
        oa[[i]] <- gsub("utslepp", "utslipp", oa[[i]])
        oa[[i]] <- gsub("uver", "uvær", oa[[i]])
        oa[[i]] <- gsub("varmar", "varm", oa[[i]])
        oa[[i]] <- gsub("varmerevåter", "varm våt", oa[[i]])
        oa[[i]] <- gsub("varmer", "varm", oa[[i]])
        oa[[i]] <- gsub("varmt", "varm", oa[[i]])
        oa[[i]] <- gsub("vatn", "vann", oa[[i]])
        oa[[i]] <- gsub("viktiger", "vikt", oa[[i]])
        oa[[i]] <- gsub("viktigst", "vikt", oa[[i]])
        oa[[i]] <- gsub("vinter", "vint", oa[[i]])
        oa[[i]] <- gsub("vintr", "vint", oa[[i]])
        oa[[i]] <- gsub("ødelagt", "ødel", oa[[i]])
        oa[[i]] <- gsub("ødelegg", "ødel", oa[[i]])
        oa[[i]] <- gsub("økend", "øke", oa[[i]])
        oa[[i]] <- gsub("øker", "øke", oa[[i]])
        oa[[i]] <- gsub("øket", "øke", oa[[i]])
        oa[[i]] <- gsub("økning", "øke", oa[[i]])
        oa[[i]] <- gsub("økt", "øke", oa[[i]])
        oa[[i]] <- gsub("", "", oa[[i]])
        oa[[i]] <- gsub("", "", oa[[i]])
    }
    return(oa)
}

prestemmed_toks <- do_pre_stemming(input$openanswer) |>
    tokens(remove_punct = TRUE, remove_numbers = TRUE)

docvars(prestemmed_toks) <- docvars(original_toks)
docnames(prestemmed_toks) <- docnames(original_toks)

current_tokens_list <- list()
current_tokens_list[["normal"]] <- original_toks
current_tokens_list[["lemmatized"]] <- lemma_toks
current_tokens_list[["prestemmed"]] <- prestemmed_toks

process_tokens <- function(setting, current_tokens_list, all_stopwords, args) {
    ## print(setting)
    verbose <- args$debug
    if (setting$token_normalization == "lemmatization") {
        current_tokens <- current_tokens_list[["lemmatized"]]
    } else if (setting$token_normalization == "none") {
        current_tokens <- current_tokens_list[["normal"]]
    } else {
        current_tokens <- current_tokens_list[["prestemmed"]]
    }
    if (setting$stopword_removal) {
        current_tokens <- current_tokens |>
            tokens_remove(
                stopwords("norwegian"),
                case_insensitive = TRUE,
                padding = FALSE,
                verbose = verbose
            )
    }
    if (setting$token_normalization == "stemming") {
        current_tokens <- tokens_wordstem(
            current_tokens,
            language = "norwegian"
        )
    }
    current_dfm <- dfm(current_tokens)
    if (setting$trimming) {
        current_dfm <- dfm_trim(
            current_dfm,
            min_docfreq = 6,
            docfreq_type = "count"
        ) ## see note
    }
    current_hash <- rlang::hash(setting)
    saveRDS(current_dfm, tmmv.get_rds_filename(setting, args$output_dir))
    gc()
    invisible(NULL)
}

purrr::walk(
    settings,
    process_tokens,
    current_tokens_list = current_tokens_list,
    args = args,
    .progress = !args$debug
)

## DEBUG_MODE: test
if (args$debug) {
    library(testthat)
    output_dir <- args$output_dir
    for (setting in settings) {
        ## print(setting)
        filename <- tmmv.get_rds_filename(setting, output_dir)
        testthat::expect_true(fs::file_exists(here(output_dir, filename)))
        current_dfm <- readRDS(here(output_dir, filename))
        features <- featnames(current_dfm)
        if (setting$token_normalization == "none") {
            testthat::expect_true("konsekvensene" %in% features)
        }
        if (setting$token_normalization == "lemmatization") {
            testthat::expect_true("konsekvens" %in% features)
        }
        if (setting$token_normalization == "stemming") {
            testthat::expect_true("konsekv" %in% features)
        }
        if (setting$stopword_removal) {
            testthat::expect_false(all(purrr::map_lgl(
                stopwords("norwegian"),
                ~ . %in% features
            )))
        } else {
            testthat::expect_true(any(purrr::map_lgl(
                stopwords("norwegian"),
                ~ . %in% features
            )))
        }
        docfreqs <- topfeatures(
            current_dfm,
            length(features),
            scheme = "docfreq"
        )
        if (setting$trimming) {
            testthat::expect_true(tail(docfreqs, 1) == 6)
        } else {
            testthat::expect_true(tail(docfreqs, 1) < 6)
        }
    }
}
