args <- tmmv.parse_args_train(slug = "takano")

settings <- tmmv.get_settings(full = TRUE)

settings <- settings |>
    purrr::keep(\(x) x$token_normalization != "stemming")


library(here)
library(keyATM)
library(quanteda)
library(purrr)
library(stm)
library(haven)
library(dplyr)
library(furrr)

anchor_setting <- tmmv.data[[args$slug]]$anchor

anchor_mod <- readRDS(tmmv.get_rds_filename(
    anchor_setting,
    here(args$output_dir)
))

set.seed(anchor_mod$random_seed)

est <- stm::estimateEffect(
    ~ time +
        selfLoss +
        connectedness +
        vastness +
        physiological +
        accommodation,
    stmobj = anchor_mod$mod,
    metadata = anchor_mod$docvars
)

## Quote: `Regarding the Japanese AWE-S, participants with higher scores on the time factor were more likely to use words related to “Spatiality” and “Scenery” (Figure 1A). In contrast, they were less likely to use words of “Humanity.”`

max_topic_index <- which.max(
    purrr::map_dbl(est$parameters, \(x) {
        mean(purrr::map_dbl(x, \(y) y$est["time"]))
    })
)
anchor_theta <- anchor_mod$theta[, max_topic_index]
## summary(anchor_mod$mod) ##look like scenary

.get_keyatm_strata_topic_func <- function(current_mod) {
    keyATM::by_strata_DocTopic(
        current_mod$mod,
        by_var = "time",
        by_values = c(4, 5),
        labels = c(4, 5)
    )
}

.get_stm_estimate_func <- function(current_mod) {
    stm::estimateEffect(
        ~ time +
            selfLoss +
            connectedness +
            vastness +
            physiological +
            accommodation,
        stmobj = current_mod$mod,
        metadata = current_mod$docvars
    ) |>
        plot(
            covariate = "time",
            model = current_mod$mod,
            method = "difference",
            cov.value1 = 5,
            cov.value2 = 4,
            omit.plot = TRUE
        )
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

res <- furrr::future_map(
    settings,
    tmmv.get_effect_size_mod,
    anchor_theta = anchor_theta,
    args = args,
    .get_keyatm_strata_topic_func = .get_keyatm_strata_topic_func,
    .get_stm_estimate_func = .get_stm_estimate_func,
    .progress = TRUE,
    .options = furrr_options(seed = NULL)
) |>
    purrr::list_rbind() |>
    write.csv(output_path, row.names = FALSE)
