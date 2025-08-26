args <- tmmv.parse_args_read(slug = "takano")
settings <- tmmv.get_settings(full = FALSE, args = args)

## 　 　 　 　 |＼　　 　 　 　 　 ／|
## 　 　 　 　 |＼＼　　 　 　 ／／|
## 　　　　 　 : 　,>　｀´￣｀´　<　 ′
## .　　　　 　 Ｖ　 　 　 　 　 　 Ｖ
## .　　　　 　 i{　●　 　 　 ●　}i
## 　　　　 　 八　 　 ､_,_, 　 　 八 　　　わけがわからないよ
## . 　 　 　 /　个 . ＿　 ＿ . 个 ',
## 　　　＿/ 　 il 　 ,'　　　 '.　 li　 ',＿_

## we can't do stemming
settings <- settings |>
    purrr::keep(\(x) x$token_normalization != "stemming")

library(dplyr)
library(RMeCab)
library(here)
library(quanteda)
library(purrr)

pilotdata <- read.csv(here("rawdata", "data_pilot_cleaned.csv"))
pilotdata <- dplyr::mutate(pilotdata, ID = rownames(pilotdata)) |>
    dplyr::select(ID, ins_1:age, -AWE.S_c) |>
    dplyr::mutate_at(vars(starts_with("AWE")), as.numeric) |>
    dplyr::mutate(
        time = (AWES_1 + AWES_2 + AWES_3 + AWES_4 + AWES_5) / 5,
        selfLoss = (AWES_6 + AWES_7 + AWES_8 + AWES_9 + AWES_10) / 5,
        connectedness = (AWES_11 + AWES_12 + AWES_13 + AWES_14 + AWES_15) / 5,
        vastness = (AWES_16 + AWES_17 + AWES_18 + AWES_19 + AWES_20) / 5,
        physiological = (AWES_21 + AWES_22 + AWES_23 + AWES_24 + AWES_25) / 5,
        accommodation = (AWES_26 + AWES_27 + AWES_28 + AWES_29 + AWES_30) / 5,
        AWES = (time +
            selfLoss +
            connectedness +
            vastness +
            physiological +
            accommodation) /
            6,
        age = as.numeric(age)
    )

data <- read.csv(here("rawdata", "data_cleaned.csv"))
data <- dplyr::mutate(data, ID = rownames(data)) |>
    dplyr::select(ID, DPES_1:age, -AWES_c) |>
    dplyr::mutate_at(vars(starts_with("AWE")), as.numeric) |>
    dplyr::mutate_at(vars(starts_with("DPES")), as.numeric) |>
    dplyr::mutate_at(vars(age), as.numeric) |>
    dplyr::mutate(
        time = (AWES_1 + AWES_2 + AWES_3 + AWES_4 + AWES_5) / 5,
        selfLoss = (AWES_6 + AWES_7 + AWES_8 + AWES_9 + AWES_10) / 5,
        connectedness = (AWES_11 + AWES_12 + AWES_13 + AWES_14 + AWES_15) / 5,
        vastness = (AWES_16 + AWES_17 + AWES_18 + AWES_19 + AWES_20) / 5,
        physiological = (AWES_21 + AWES_22 + AWES_23 + AWES_24 + AWES_25) / 5,
        accommodation = (AWES_26 + AWES_27 + AWES_28 + AWES_29 + AWES_30) / 5,
        AWES = (time +
            selfLoss +
            connectedness +
            vastness +
            physiological +
            accommodation) /
            6
    ) |>
    dplyr::mutate(
        joy = (DPES_1 + DPES_2 + DPES_5 + DPES_7 + DPES_12 + DPES_18) / 6,
        amusement = (DPES_3 + DPES_6 + DPES_8 + DPES_26 + DPES_38) / 5,
        awe = (DPES_4 + DPES_16 + DPES_17 + DPES_22 + DPES_31 + DPES_36) / 6,
        contentment = (DPES_9 + DPES_10 + DPES_20 + DPES_24 + DPES_29) / 5,
        love = (DPES_11 + DPES_19 + DPES_21 + DPES_25 + DPES_28 + DPES_34) / 6,
        pride = (DPES_13 + DPES_15 + DPES_23 + DPES_27 + DPES_33) / 5,
        compassion = (DPES_14 + DPES_30 + DPES_32 + DPES_35 + DPES_37) / 5
    ) |>
    dplyr::mutate(
        vastness2 = ifelse(vastness >= 6.20, 1, 0),
        AWES2 = (time +
            selfLoss +
            connectedness +
            vastness2 +
            physiological +
            accommodation) /
            6
    )


data_nlp_sum <- bind_rows(
    data |>
        dplyr::select(
            ins_1,
            gender,
            age,
            time,
            selfLoss,
            connectedness,
            vastness,
            physiological,
            accommodation,
            AWES,
            ID
        ),
    pilotdata |>
        dplyr::select(
            ins_1,
            gender,
            age,
            time,
            selfLoss,
            connectedness,
            vastness,
            physiological,
            accommodation,
            AWES,
            ID
        )
)

## default Genkei = 0, i.e. lemmatize
## so Genkei = 1: token_normalization = "none"

## print(docDF(data.frame(text = "自然は偉大でかなわないと思いました。"), "text", type = 1, pos = NULL, minFreq = 1, Genkei = 1))
## print(docDF(data.frame(text = "自然は偉大でかなわないと思いました。"), "text", type = 1, pos = NULL, minFreq = 1, Genkei = 0))

process_text <- function(data_nlp_sum, lemmatize = TRUE) {
    stfu_docDF <- purrr::quietly(RMeCab::docDF)
    terms_df <- stfu_docDF(
        data_nlp_sum,
        "ins_1",
        type = 1,
        pos = NULL,
        minFreq = 1,
        Genkei = as.numeric(!lemmatize)
    )$result
    dfm_raw <- terms_df |>
        select(-TERM, -POS1, -POS2) |>
        as.matrix() |>
        t()
    colinfo <- terms_df |>
        select(TERM, POS1, POS2)
    stopifnot(nrow(colinfo) == ncol(dfm_raw))
    output <- list()
    output$dfm <- as.dfm(dfm_raw)
    docvars(output$dfm) <- select(data_nlp_sum, -ins_1)
    output$meta <- colinfo
    return(output)
}

current_tokens_list <- list()
current_tokens_list[["normal"]] <- process_text(data_nlp_sum, lemmatize = FALSE)
current_tokens_list[["lemmatized"]] <- process_text(
    data_nlp_sum,
    lemmatize = TRUE
)

process_tokens <- function(setting, current_tokens_list, args) {
    if (setting$token_normalization == "lemmatization") {
        current_tokens <- current_tokens_list[["lemmatized"]]
    } else {
        current_tokens <- current_tokens_list[["normal"]]
    }
    mask <- rep(FALSE, ncol(current_tokens$dfm))
    if (setting$stopword_removal) {
        mask <- mask |
            (current_tokens$meta$TERM %in%
                c(
                    ",",
                    "ない",
                    "ある",
                    "いい",
                    "いう",
                    "おる",
                    "くだ",
                    "しれる",
                    "やる"
                ))
    }
    if (setting$trimming) {
        ##
        mask <- mask |
            docfreq(current_tokens$dfm) < 3 |
            docfreq(current_tokens$dfm) > 100
        ## trim POS
        mask <- mask |
            !(current_tokens$meta$POS1 %in% c("動詞", "名詞", "形容詞"))
        ## trim POS2
        mask <- mask |
            (current_tokens$meta$POS2 %in% c("数", "代名詞", "接尾", "非自立"))
    }
    current_dfm <- current_tokens$dfm[, !mask]
    colnames(current_dfm) <- current_tokens$meta$TERM[!mask]
    current_hash <- rlang::hash(setting)
    ##print(current_hash)
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

if (args$debug) {
    library(testthat)
    all_stopwords <- c(
        ",",
        "ない",
        "ある",
        "いい",
        "いう",
        "おる",
        "くだ",
        "しれる",
        "やる"
    )
    for (setting in settings) {
        ## print(setting)
        output_dir <- args$output_dir
        filename <- paste0(rlang::hash(setting), ".RDS")
        testthat::expect_true(file.exists(here(output_dir, filename)))
        current_dfm <- readRDS(here(output_dir, filename))
        features <- featnames(current_dfm)
        if (setting$token_normalization == "none") {
            testthat::expect_true("思い" %in% features)
        }
        if (setting$token_normalization == "lemmatization") {
            testthat::expect_true("思う" %in% features)
        }
        if (setting$stopword_removal) {
            testthat::expect_false(all(purrr::map_lgl(
                all_stopwords,
                ~ . %in% features
            )))
        } else {
            testthat::expect_true(any(purrr::map_lgl(
                all_stopwords,
                ~ . %in% features
            )))
        }
        if (setting$trimming) {
            testthat::expect_true(
                topfeatures(current_dfm, scheme = "docfreq", n = 1) <= 100
            )
        } else {
            testthat::expect_false(
                topfeatures(current_dfm, scheme = "docfreq", n = 1) <= 100
            )
        }
    }
}
