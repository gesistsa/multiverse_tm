## TEMP
args <- tmmv.parse_args_train(slug = "czymara", debug = TRUE)
args$output_dir <- here::here("intermediate/czymara/runs/1")

settings <- tmmv.get_settings(full = TRUE, args = NULL, .nothing_quit = FALSE)

library(here)
library(keyATM)
library(quanteda)
library(purrr)
library(stm)
library(haven)
library(dplyr)

input <- haven::read_dta(here("rawdata/Corona-Survey_full.dta"))
data_priv <- input |>
    mutate(gender = case_match(DE03,
                               1 ~ "male",
                               2 ~ "female",
                               .default = NA_character_)) |>
    filter(!is.na(gender)) |> ##NOTE1
    mutate(gender = factor(gender, levels = c("male", "female"))) |> #NOTE2
    mutate(OF01_01 = stringr::str_trim(OF01_01)) |>
    filter(OF01_01 != "" &
           !stringr::str_detect(OF01_01, "^[[:space:]]+$")) ##NOTE3
    
corpus_priv <- corpus(as.character(data_priv$OF01_01),
                      docvars = data.frame(gender = data_priv$gender,
                                           id = data_priv$CASE))

## the original setting in Czymara
anchor_setting <- list()
anchor_setting$token_normalization <- "stemming"
anchor_setting$stopword_removal <- TRUE
anchor_setting$trimming <- TRUE
anchor_setting$alternative_model <- FALSE
anchor_setting$k_setting <- 1
anchor_setting$iteration_setting <- 1

anchor_mod <- readRDS(here(args$output_dir, paste0(rlang::hash(anchor_setting), ".RDS")))

est <- estimateEffect(1:8~gender, stmobj = anchor_mod$mod, metadata = anchor_mod$docvars)


## Note that by default stm is 1 - 2
## https://github.com/bstewart/stm/blob/dbabf3405c660452bffc8bd1aaf72f7ea3867319/R/plottingutilfns.R#L168
res <- plot(est, covariate = "gender",
            model = anchor_mod$mod, method = "difference",
            cov.value1 = "female", cov.value2 = "male",
            omit.plot = TRUE)

max_topic_index <- which.max(as.vector(res$means))
anchor_theta <- anchor_mod$theta[,max_topic_index]

## as.character(corpus_priv[which.max(anchor_theta)])
## docvars(corpus_priv, "gender")[which.max(anchor_theta)]



first_setting <- settings[[1]]
second_setting <- settings[[1]]
second_setting$alternative_model <- !second_setting$alternative_model

mod1 <- train_model(first_setting, args = args, .return_output = TRUE, .fix_seed = 1111)
mod2 <- train_model(second_setting, args = args, .return_output = TRUE, .fix_seed = 1111)

top_words(mod1$mod)
summary(mod2$mod)

strata_topic <- by_strata_DocTopic(mod1$mod, by_var = "genderfemale", labels = c("male", "female"))

summary(strata_topic)

theta1 <- strata_topic$theta[[1]]
theta2 <- strata_topic$theta[[2]]

theta_diff <- theta2[, 1:8] - theta1[, 1:8]

theta_diff_quantile <- apply(theta_diff, 2, quantile, c(0.05, 0.5, 0.95))

top_words(mod1$mod)

summary(mod2$mod)

est <- estimateEffect(1:8~gender, stmobj = mod2$mod, metadata = mod2$docvars)


## Note that by default stm is 1 - 2
## https://github.com/bstewart/stm/blob/dbabf3405c660452bffc8bd1aaf72f7ea3867319/R/plottingutilfns.R#L168
res <- plot(est, covariate = "gender",
            model = mod2$mod, method = "difference",
            cov.value1 = "female", cov.value2 = "male", omit.plot = TRUE
            )

res$means

res$means[[8]]
res$cis[[8]]

#1
sapply(1:8, function(x) cor(mod2$theta[,8], mod1$theta[,x], method = "spearman")) |> which.max()


theta_diff_quantile[,1]

top_words(mod1$mod)[1]


labeltopics(mod2$mod)$frex[8,]
