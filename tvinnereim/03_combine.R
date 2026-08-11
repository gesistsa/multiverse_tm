args <- tmmv.parse_args_train(slug = "tvinnereim")

settings <- tmmv.get_settings(full = TRUE)

library(here)
library(keyATM)
library(quanteda)
library(purrr)
library(stm)
library(dplyr)
library(furrr)

anchor_setting <- tmmv.data[[args$slug]]$anchor

anchor_mod <- readRDS(tmmv.get_rds_filename(
    anchor_setting,
    here(args$output_dir)
))

set.seed(anchor_mod$random_seed)

est <- stm::estimateEffect(
    ~ concern + edu3 + gender + age,
    stmobj = anchor_mod$mod,
    metadata = anchor_mod$docvars
)

## It is not the same as Czymara because it's continuous
max_topic_index <- which.max(
    purrr::map_dbl(est$parameters, \(x) {
        mean(purrr::map_dbl(x, \(y) y$est["age"]))
    })
)
anchor_theta <- anchor_mod$theta[, max_topic_index]

.get_keyatm_strata_topic_func <- function(current_mod) {
    keyATM::by_strata_DocTopic(
        current_mod$mod,
        by_var = "age",
        by_values = c(3, 4),
        labels = c(3, 4)
    )
}
.get_stm_estimate_func <- function(current_mod) {
    stm::estimateEffect(
        ~ concern + humanmade + efficacy + edu3 + gender + age,
        stmobj = current_mod$mod,
        metadata = current_mod$docvars
    ) |>
        plot(
            covariate = "age",
            model = current_mod$mod,
            method = "difference",
            cov.value1 = 4,
            cov.value2 = 3,
            omit.plot = TRUE
        )
}

if (args$debug) {
    plan(sequential)
} else {
    plan(multisession, workers = getOption("tmmv.cores", 1))
}

furrr::future_map(
    settings,
    tmmv.get_effect_size_mod,
    anchor_theta = anchor_theta,
    args = args,
    .get_keyatm_strata_topic_func = .get_keyatm_strata_topic_func,
    .get_stm_estimate_func = .get_stm_estimate_func,
    .progress = TRUE,
    .options = furrr_options(seed = NULL)
) |>
    tmmv.postprocess_effect_size_mod(args = args)
