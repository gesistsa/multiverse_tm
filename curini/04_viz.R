library(here)
library(dplyr)
library(ggplot2)
library(cowplot)
library(stringr)
library(tidyr)
library(purrr)

slug <- "curini"

read.csv(here("results", "aggregated", slug, "1.csv")) |>
    tmmv.plot_spec_curve(tmmv.data[[slug]])

purrr::map(1:3, \(x) {
    read.csv(here("results", "aggregated", slug, paste0(x, ".csv")))
}) |>
    tmmv.plot_spec_curve(tmmv.data[[slug]])


## conditional effect plot

condit_effect <- read.csv(here::here(
    "results",
    "aggregated",
    slug,
    "condit_1.csv"
))

## find out currini's setting
curini_setting <- list()
curini_setting$token_normalization <- "stemming"
curini_setting$stopword_removal <- TRUE
curini_setting$trimming <- FALSE
curini_setting$alternative_model <- FALSE
curini_setting$k_setting <- 1
curini_setting$iteration_setting <- 1

curini_hash <- rlang::hash(curini_setting)

## curini_hash %in% condit_effect$hash

condit_effect |>
    ggplot(aes(x = LR, y = pred_multi100, group = hash)) +
    geom_line(alpha = 0.05) +
    geom_line(data = condit_effect[condit_effect$hash == curini_hash, ]) +
    xlab("LR") +
    ylab(expression(theta)) +
    theme_minimal()
