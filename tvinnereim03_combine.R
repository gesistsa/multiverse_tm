args <- tmmv.parse_args_train(slug = "tvinnereim")

settings <- tmmv.get_settings(full = TRUE)

library(here)
library(keyATM)
library(quanteda)
library(purrr)
library(stm)
library(dplyr)
library(furrr)

## the original setting in tvinnereim
anchor_setting <- list()
anchor_setting$token_normalization <- "stemming"
anchor_setting$stopword_removal <- TRUE
anchor_setting$trimming <- TRUE
anchor_setting$alternative_model <- FALSE
anchor_setting$k_setting <- 1
anchor_setting$iteration_setting <- 1

anchor_mod <- readRDS(here(args$output_dir, paste0(rlang::hash(anchor_setting), ".RDS")))

set.seed(anchor_mod$random_seed)

## This in the original source is kind of unexplained

## univdummy <- as.numeric(meta$edu3==3)
## print(univdummy)  
## summary(univdummy)
## table(meta$edu3, univdummy)
## meta$univdummy <- univdummy

## but let's do it anyway

anchor_mod$docvars$univdummy <- as.numeric(anchor_mod$docvars$edu3==3)

est <- stm::estimateEffect(~concern+univdummy+gender+age, stmobj = anchor_mod$mod, metadata = anchor_mod$docvars)

## It is not the same as Czymara because it's continuous
max_topic_index <- which.max(
    purrr::map_dbl(est$parameters,
                   \(x) mean(purrr::map_dbl(x, \(y) y$est["age"]))))
anchor_theta <- anchor_mod$theta[,max_topic_index]

get_effect_size_mod <- function(setting, anchor_theta) {
    current_mod <- readRDS(here(args$output_dir,
                                paste0(rlang::hash(setting), ".RDS")))
    k <- ncol(current_mod$theta)
    if (setting$alternative_model) {
        strata_topic <- keyATM::by_strata_DocTopic(current_mod$mod, by_var = "age", by_values = c(3, 4), labels = c(3,4))
        theta1 <- strata_topic$theta[[1]]
        theta2 <- strata_topic$theta[[2]]
        theta_diff <- theta2[, seq_len(k)] - theta1[, seq_len(k)]       
        theta_diff_quantile <- apply(theta_diff, 2, quantile, c(0.025, 0.975))
        theta_diff_mean <- apply(theta_diff, 2, mean)
        anchor_index <- tmmv.find_anchor(anchor_theta, current_mod$theta)
        anchor_index <- tmmv.find_anchor(anchor_theta, current_mod$theta)
        output <- data.frame(Estimate = theta_diff_mean[anchor_index],
                             Q2.5 = theta_diff_quantile[1, anchor_index],
                             Q97.5 = theta_diff_quantile[2, anchor_index])
        rownames(output) <- NULL
    } else {
        est <- stm::estimateEffect(~concern+humanmade+efficacy+edu3+gender+age, stmobj = current_mod$mod, metadata = current_mod$docvars)

        res <- plot(est, covariate = "age",
                    model = current_mod$mod, method = "difference",
                    cov.value1 = 4, cov.value2 = 3,
                    omit.plot = TRUE)

        anchor_index <- tmmv.find_anchor(anchor_theta, current_mod$theta)
        anchor_index <- tmmv.find_anchor(anchor_theta, current_mod$theta)
        output <- data.frame(Estimate = as.vector(res$means)[anchor_index],
                             Q2.5 = res$cis[[anchor_index]][1],
                             Q97.5 = res$cis[[anchor_index]][2])
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

output_path <- here::here("results", "aggregated", args$slug, paste0(args$current_run, ".csv"))

## Note that it uses the random seed from L41
res <- furrr::future_map(settings, get_effect_size_mod,
                         anchor_theta = anchor_theta,
                         .progress = TRUE,
                         .options = furrr_options(seed = NULL)) |>
    purrr::list_rbind() |>
    write.csv(output_path, row.names = FALSE)
