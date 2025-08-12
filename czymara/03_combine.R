args <- tmmv.parse_args_train(slug = "czymara")

settings <- tmmv.get_settings(full = TRUE)

library(here)
library(keyATM)
library(quanteda)
library(purrr)
library(stm)
library(haven)
library(dplyr)
library(furrr)

## input <- haven::read_dta(here("rawdata/Corona-Survey_full.dta"))
## data_priv <- input |>
##     mutate(gender = case_match(DE03,
##                                1 ~ "male",
##                                2 ~ "female",
##                                .default = NA_character_)) |>
##     filter(!is.na(gender)) |> ##NOTE1
##     mutate(gender = factor(gender, levels = c("male", "female"))) |> #NOTE2
##     mutate(OF01_01 = stringr::str_trim(OF01_01)) |>
##     filter(OF01_01 != "" &
##            !stringr::str_detect(OF01_01, "^[[:space:]]+$")) ##NOTE3

## corpus_priv <- corpus(as.character(data_priv$OF01_01),
##                       docvars = data.frame(gender = data_priv$gender,
##                                            id = data_priv$CASE))

## the original setting in Czymara
anchor_setting <- list()
anchor_setting$token_normalization <- "stemming"
anchor_setting$stopword_removal <- TRUE
anchor_setting$trimming <- TRUE
anchor_setting$alternative_model <- FALSE
anchor_setting$k_setting <- 1
anchor_setting$iteration_setting <- 1

anchor_mod <- readRDS(here(
    args$output_dir,
    paste0(rlang::hash(anchor_setting), ".RDS")
))

set.seed(anchor_mod$random_seed)

est <- stm::estimateEffect(
    ~gender,
    stmobj = anchor_mod$mod,
    metadata = anchor_mod$docvars
)


## Note that by default stm is 1 - 2
## https://github.com/bstewart/stm/blob/dbabf3405c660452bffc8bd1aaf72f7ea3867319/R/plottingutilfns.R#L168
res <- plot(
    est,
    covariate = "gender",
    model = anchor_mod$mod,
    method = "difference",
    cov.value1 = "female",
    cov.value2 = "male",
    omit.plot = TRUE
)

max_topic_index <- which.max(as.vector(res$means))
anchor_theta <- anchor_mod$theta[, max_topic_index]

## as.character(corpus_priv[which.max(anchor_theta)])
## docvars(corpus_priv, "gender")[which.max(anchor_theta)]

get_effect_size_mod <- function(setting, anchor_theta) {
    current_mod <- readRDS(here(
        args$output_dir,
        paste0(rlang::hash(setting), ".RDS")
    ))
    k <- ncol(current_mod$theta)
    if (setting$alternative_model) {
        strata_topic <- keyATM::by_strata_DocTopic(
            current_mod$mod,
            by_var = "genderfemale",
            labels = c("male", "female")
        )
        theta1 <- strata_topic$theta[[1]]
        theta2 <- strata_topic$theta[[2]]

        theta_diff <- theta2[, seq_len(k)] - theta1[, seq_len(k)]

        theta_diff_quantile <- apply(theta_diff, 2, quantile, c(0.025, 0.975))
        theta_diff_mean <- apply(theta_diff, 2, mean)

        anchor_index <- tmmv.find_anchor(anchor_theta, current_mod$theta)
        output <- data.frame(
            Estimate = theta_diff_mean[anchor_index],
            Q2.5 = theta_diff_quantile[1, anchor_index],
            Q97.5 = theta_diff_quantile[2, anchor_index]
        )
        rownames(output) <- NULL
    } else {
        est <- stm::estimateEffect(
            ~gender,
            stmobj = current_mod$mod,
            metadata = current_mod$docvars
        )
        res <- plot(
            est,
            covariate = "gender",
            model = current_mod$mod,
            method = "difference",
            cov.value1 = "female",
            cov.value2 = "male",
            omit.plot = TRUE
        )
        anchor_index <- tmmv.find_anchor(anchor_theta, current_mod$theta)
        output <- data.frame(
            Estimate = as.vector(res$means)[anchor_index],
            Q2.5 = res$cis[[anchor_index]][1],
            Q97.5 = res$cis[[anchor_index]][2]
        )
        colnames(output) <- c("Estimate", "Q2.5", "Q97.5")
        rownames(output) <- NULL
    }
    output <- round(output, 6)
    return(cbind(as.data.frame(setting), output))
}

if (args$debug) {
    plan(sequential)
} else {
    plan(multisession, workers = getOption("tmmv.cores", 1))
}

output_path <- here::here(
    "results",
    "aggregated",
    args$slug,
    paste0(args$current_run, ".csv")
)

## Note that it uses the random seed from L41
res <- furrr::future_map(
    settings,
    get_effect_size_mod,
    anchor_theta = anchor_theta,
    .progress = TRUE,
    .options = furrr_options(seed = NULL)
) |>
    purrr::list_rbind() |>
    write.csv(output_path, row.names = FALSE)
