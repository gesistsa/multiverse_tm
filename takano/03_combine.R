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

anchor_setting <- list()
anchor_setting$token_normalization <- "lemmatization"
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
summary(anchor_mod$mod) ##look like scenary

get_effect_size_mod <- function(setting, anchor_theta) {
    current_mod <- readRDS(here(
        args$output_dir,
        paste0(rlang::hash(setting), ".RDS")
    ))
    set.seed(current_mod$random_seed)
    k <- ncol(current_mod$theta)
    if (setting$alternative_model) {
        strata_topic <- keyATM::by_strata_DocTopic(
            current_mod$mod,
            by_var = "time",
            by_values = c(4, 5),
            labels = c(4, 5)
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
            ~ time +
                selfLoss +
                connectedness +
                vastness +
                physiological +
                accommodation,
            stmobj = current_mod$mod,
            metadata = current_mod$docvars
        )

        res <- plot(
            est,
            covariate = "time",
            model = current_mod$mod,
            method = "difference",
            cov.value1 = 5,
            cov.value2 = 4,
            omit.plot = TRUE
        )

        anchor_index <- tmmv.find_anchor(anchor_theta, current_mod$theta)
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
    hash <- rlang::hash(setting)
    theta <- current_mod$theta[, anchor_index, drop = FALSE]
    colnames(theta) <- hash
    return(list(
        multiverse = cbind(as.data.frame(setting), output),
        theta = theta
    ))
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
    get_effect_size_mod,
    anchor_theta = anchor_theta,
    .progress = TRUE,
    .options = furrr_options(seed = NULL)
)

res |>
    purrr::map("multiverse") |>
    purrr::list_rbind() |>
    write.csv(output_path, row.names = FALSE)

res |>
    purrr::map("theta") |>
    purrr::map(as.data.frame) |>
    purrr::list_cbind() |>
    round(6) -> thetas

theta_path <- here::here(
    "intermediate",
    args$slug,
    "runs",
    args$current_run,
    "theta",
    "anchor_by_original_setting.csv"
)

write.csv(thetas, theta_path, row.names = FALSE)
