## We need to source it here
source(here::here("lib/lib.R"))

test_readtext_base <- function() {
    x <- quanteda::corpus(
        tmmv.read_text_base(
            here::here("dev/TXT"),
            dvsep = "_",
            docvarnames = c("Country", "Session", "Year")
        )
    )

    ungd_files <- readtext::readtext(
        here::here("dev/TXT"),
        docvarsfrom = "filenames",
        dvsep = "_",
        docvarnames = c("Country", "Session", "Year")
    )
    y <- quanteda::corpus(ungd_files)
    for (i in sample(seq_len(quanteda::ndoc(x)), 100)) {
        testthat::expect_equal(x[i], y[i])
    }
}

test_lemmatize_words <- function() {
    ungd_files <- readtext::readtext(
        here::here("dev/TXT"),
        dvsep = "_",
        docvarnames = c("Country", "Session", "Year")
    )

    ungd_files$doc_id <- stringr::str_replace(ungd_files$doc_id, ".txt", "") |>
        stringr::str_replace("_\\d{2}", "")

    ungd_corpus <- quanteda::corpus(ungd_files, text_field = "text")

    ungd_tokens <- quanteda::tokens(
        ungd_corpus,
        what = "word",
        remove_punct = TRUE,
        remove_symbols = TRUE,
        remove_numbers = TRUE,
        remove_url = TRUE,
        split_hyphens = FALSE,
        verbose = TRUE
    ) |>
        quanteda::tokens_tolower()

    ori_types <- attr(ungd_tokens, "types")
    textstem_lemmatized <- textstem::lemmatize_words(ori_types)
    our_lemmatized <- tmmv.lemmatize_words(ori_types)
    testthat::expect_identical(textstem_lemmatized, our_lemmatized)
}

test_get_settings <- function() {
    x <- tmmv.get_settings(full = TRUE)
    testthat::expect_equal(length(x), 216)
    y <- tmmv.get_settings(full = FALSE)
    testthat::expect_equal(length(y), 12)
    testthat::expect_false(is.factor(y[[1]]$token_normalization))
    testthat::expect_true(is.character(y[[1]]$token_normalization))
}

test_get_settings_filter <- function() {
    withr::with_tempdir({
        wd <- getwd()
        args <- list()
        args$output_dir <- wd
        args$debug <- FALSE
        x <- tmmv.get_settings(full = TRUE, args = args)
        for (i in sample(seq_along(x), 10)) {
            saveRDS(iris, file.path(wd, paste0(rlang::hash(x[[i]]), ".RDS")))
        }
        y1 <- tmmv.get_settings(full = TRUE, args = args)
        testthat::expect_true(length(x) - length(y1) == 10)
        args2 <- args
        args2$debug <- TRUE
        y2 <- tmmv.get_settings(full = TRUE, args = args2)
        testthat::expect_false(length(x) - length(y2) == 10)
    })
    withr::with_tempdir({
        wd <- getwd()
        args <- list()
        args$output_dir <- wd
        args$debug <- FALSE
        x <- tmmv.get_settings(full = FALSE, args = args)
        for (i in sample(seq_along(x), 10)) {
            saveRDS(iris, file.path(wd, paste0(rlang::hash(x[[i]]), ".RDS")))
        }
        y1 <- tmmv.get_settings(full = FALSE, args = args)
        testthat::expect_true(length(x) - length(y1) == 10)
        args2 <- args
        args2$debug <- TRUE
        y2 <- tmmv.get_settings(full = FALSE, args = args2)
        testthat::expect_false(length(x) - length(y2) == 10)
    })
}

test_get_current <- function() {
    settings <- tmmv.get_settings()
    args <- list()
    args$debug <- FALSE
    a_iter <- c(800, 300, 100)
    b_iter <- c(8000, 3000, 1000)
    k <- c(7, 2, 1)
    a_keywords <- list(videogame = c("metroid", "castlevania"))
    b_keywords <- list(boring = c("llm", "ai", "css"))
    for (i in seq_along(settings)) {
        setting <- settings[[i]]
        current <- tmmv.get_current(
            setting,
            args = args,
            keywords = a_keywords,
            stemmed_keywords = b_keywords,
            k = k,
            original_iter = a_iter,
            alternative_iter = b_iter,
            .fix_seed = NULL
        )
        testthat::expect_equal(k[setting$k_setting], current$k)
        if (!setting$alternative_model) {
            testthat::expect_equal(
                a_iter[setting$iteration_setting],
                current$iter
            )
        } else {
            testthat::expect_equal(
                b_iter[setting$iteration_setting],
                current$iter
            )
        }
        if (setting$token_normalization == "stemming") {
            testthat::expect_equal(names(current$keywords), "boring")
        } else {
            testthat::expect_equal(names(current$keywords), "videogame")
        }
    }
    current <- tmmv.get_current(
        settings[[1]],
        args = args,
        keywords = a_keywords,
        stemmed_keywords = b_keywords,
        k = k,
        original_iter = a_iter,
        alternative_iter = b_iter,
        .fix_seed = 721
    )
    testthat::expect_equal(current$random_seed, 721)

    args2 <- args
    args2$debug <- TRUE
    current <- tmmv.get_current(
        settings[[1]],
        args = args2,
        keywords = a_keywords,
        stemmed_keywords = b_keywords,
        k = k,
        original_iter = a_iter,
        alternative_iter = b_iter,
        .fix_seed = 721
    )
    testthat::expect_equal(100, current$iter)

    ## without providing stemmed_keywords
    setting2 <- settings[[1]]
    setting2$token_normalization <- "stemming"
    current <- tmmv.get_current(
        setting2,
        args = args2,
        keywords = a_keywords,
        k = k,
        original_iter = a_iter,
        alternative_iter = b_iter,
        .fix_seed = 721
    )
    testthat::expect_equal(names(current$keywords), "videogame")
    setting2 <- settings[[1]]
    setting2$token_normalization <- "none"
    current <- tmmv.get_current(
        setting2,
        args = args2,
        keywords = a_keywords,
        k = k,
        original_iter = a_iter,
        alternative_iter = b_iter,
        .fix_seed = 721
    )
    testthat::expect_equal(names(current$keywords), "videogame")
}

test_create_dir <- function() {
    withr::with_tempdir({
        wd <- getwd()
        args <- list()
        args$output_dir <- file.path(wd, "intermediate", "1")
        testthat::expect_error(tmmv.create_dir(args), NA)
        testthat::expect_true(dir.exists(args$output_dir)) ## #13
        ## ontop
        testthat::expect_error(tmmv.create_dir(args, ontop = "brms"), NA)
        testthat::expect_true(dir.exists(file.path(args$output_dir, "brms")))
        ## clean
        write.csv(iris, file.path(args$output_dir, "brms", "iris.csv"))
        testthat::expect_true(file.exists(file.path(
            args$output_dir,
            "brms",
            "iris.csv"
        )))
        testthat::expect_error(tmmv.create_dir(args, ontop = "brms"), NA)
        testthat::expect_true(file.exists(file.path(
            args$output_dir,
            "brms",
            "iris.csv"
        )))
        testthat::expect_error(
            tmmv.create_dir(args, ontop = "brms", clean = TRUE),
            NA
        )
        testthat::expect_false(file.exists(file.path(
            args$output_dir,
            "brms",
            "iris.csv"
        )))
    })
}

testthat::test_that("tests", {
    test_get_settings()
    test_get_settings_filter()
    test_get_current()
    test_create_dir()
    if (dir.exists(here::here("dev/TXT"))) {
        test_readtext_base()
        test_lemmatize_words()
    }
})
