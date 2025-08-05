args <- tmmv.parse_args_train(slug = "tvinnereim", .current_run = 1)

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

setting <- settings[[204]]

current_mod <- readRDS(here(args$output_dir,
                            paste0(rlang::hash(setting), ".RDS")))
k <- ncol(current_mod$theta)

strata_topic <- keyATM::by_strata_DocTopic(current_mod$mod, by_var = "age", labels = 1:7)

strata_topic$theta[[1]]

