args <- tmmv.parse_args_train(slug = "czymara", debug = TRUE)

settings <- tmmv.get_settings(full = TRUE, args = NULL, .nothing_quit = FALSE)

library(here)
library(keyATM)
library(quanteda)
library(purrr)
library(stm)

#' This function unifies the theta so that the output theta always
#' has the same nrow as current_dfm
#' The raison d'être is that stm discards empty rows sliently
#' But doesn't retain the rownames
unify_theta <- function(mod, trimmed_dfm, current_dfm) {
    theta <- mod$theta
    rownames(theta) <- docnames(trimmed_dfm)

    excluded_docs <- setdiff(docnames(current_dfm), docnames(trimmed_dfm))
    k <- ncol(theta)
    fake_theta <- matrix(rep(1/k, length(excluded_docs) * k), nrow = length(excluded_docs), ncol = k)
    rownames(fake_theta) <- excluded_docs
    final_theta <- rbind(theta, fake_theta)

    final_theta <- final_theta[match(rownames(current_dfm),rownames(final_theta)) ,]
    return(final_theta)
}

train_model <- function(setting, args, .fix_seed = NULL, .return_output = FALSE) {

    dfm_filename <- paste0(rlang::hash(setting[1:3]), ".RDS")
    current_dfm <- readRDS(here(args$prefix, args$slug, dfm_filename))

    current <- tmmv.get_current(setting = setting,
                                args = args,
                                k = c(8, 6, 10),
                                original_iter = c(500, round(500 * 0.8), round(500 * 1.2)),
                                alternative_iter = c(2000, round(2000 * 0.8), round(2000 * 1.2)),
                                .fix_seed = .fix_seed)

    output <- list()
    output$random_seed <- current$random_seed
    output$setting <- setting

    ## STM drops rows slightly, we do it here explicitly
    rowsum_priv <- apply(current_dfm, 1, sum)
    trimmed_dfm <- current_dfm[rowsum_priv != 0, ]

    set.seed(current$random_seed)

    if (!setting$alternative_model) {
        output$mod <- stm(trimmed_dfm,
                          K = current$k,
                          init.type = "Spectral",
                          max.em.its = current$iter,
                          prevalence = ~gender,
                          verbose = args$debug,
                          data = trimmed_dfm@docvars)
    } else {
        keyATM_docs <- keyATM_read(texts = trimmed_dfm)

        output$mod <- weightedLDA(docs = keyATM_docs,
                                  number_of_topics = current$k,
                                  model = "covariates",
                                  model_settings = list(
                                      covariates_data = trimmed_dfm@docvars,
                                      covariates_formula = ~ gender),
                                  options = list(
                                      iterations = current$iter,
                                      verbose = args$debug)
                                  )
    }
    output$theta <- unify_theta(output$mod, trimmed_dfm, current_dfm)
    if (.return_output) {
        return(output)
    }
    current_hash <- rlang::hash(setting)
    saveRDS(output, file.path(args$output_dir, paste0(current_hash, ".RDS")))
}

first_setting <- settings[[1]]
second_setting <- settings[[1]]
second_setting$alternative_model <- !second_setting$alternative_model

mod1 <- train_model(first_setting, args = args, .return_output = TRUE, .fix_seed = 123)
mod2 <- train_model(second_setting, args = args, .return_output = TRUE, .fix_seed = 123)

top_words(mod1$mod)
summary(mod2$mod)

strata_topic <- by_strata_DocTopic(mod1$mod, by_var = "gendermale", labels = c("male", "female"))

summary(strata_topic)

theta1 <- strata_topic$theta[[1]]
theta2 <- strata_topic$theta[[2]]

theta_diff <- theta1[, 1:8] - theta2[, 1:8]

theta_diff_quantile <- apply(theta_diff, 2, quantile, c(0.05, 0.5, 0.95))


## damn needa produce it again
dfm_filename <- paste0(rlang::hash(first_setting[1:3]), ".RDS")
current_dfm <- readRDS(here(args$prefix, args$slug, dfm_filename))
rowsum_priv <- apply(current_dfm, 1, sum)
trimmed_dfm <- current_dfm[rowsum_priv != 0, ]

est <- estimateEffect(1:8~gender, stmobj = mod2$mod, metadata = trimmed_dfm@docvars)


plot(est, covariate = "gender",
     model = mod2$mod, method = "difference",
     cov.value1 = "male", cov.value2 = "female"
     )


#7
sapply(1:8, function(x) cor(mod2$theta[,8], mod1$theta[,x], method = "spearman")) |> which.max()

summary(mod2$mod)

## the effect size is similar ~0.03
theta_diff_quantile[,7]

used_covariates <- covariates_get(mod1$mod)
