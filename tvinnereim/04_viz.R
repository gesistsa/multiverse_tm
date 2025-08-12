library(here)
library(dplyr)
library(ggplot2)

library(cowplot)
# library("dplyr")
# library("ggplot2")
# library("here")
library(stringr)
library(tidyr)

results <- read.csv(here("results", "aggregated", "tvinnereim", "1.csv"))

plot_a <- results |>
    arrange(Estimate) |>
    mutate(
        specifications = 1:nrow(results),
        color = case_when(
            Q2.5 > 0 ~ "green",
            Q97.5 < 0 ~ "#377eb8",
            is.na(Estimate) ~ "#e41a1c",
            TRUE ~ "darkgrey"
        )
    ) |>
    ggplot(aes(
        x = specifications,
        y = Estimate,
        ymin = Q2.5,
        ymax = Q97.5,
        color = color
    )) +
    geom_point(aes(color = color), size = 1) +
    theme_minimal() +
    scale_color_identity() +
    theme(
        strip.text = element_blank(),
        axis.line = element_line("black", linewidth = .5),
        legend.position = "none",
        panel.spacing = unit(0.75, "lines"),
        axis.text = element_text(colour = "black")
    ) +
    labs(x = "", y = "Median [95% Cr. I.]") +
    geom_pointrange(alpha = 0.5, size = 0.6, fatten = 1) +
    geom_hline(yintercept = 0, colour = "black", linetype = "dotted")

value <- key <- NULL
choices = c("Tok. Norm.", "Stopword Rem.", "Trim.", "Alt. Model", "k", "Iter.")

# Todo: Panel B of the entire plot still displays k and iteration settings as
# 1, 2, 3. I suppose that this should actually display the actual values used.
plot_b <- results |>
    arrange(Estimate) |>
    mutate(
        specifications = 1:nrow(results),
        color = case_when(
            Q2.5 > 0 ~ "green",
            Q97.5 < 0 ~ "#377eb8",
            is.na(Estimate) ~ "#e41a1c",
            TRUE ~ "darkgrey"
        )
    ) |>
    mutate(
        token_normalization = case_when(
            str_equal(token_normalization, "none") ~ "None",
            str_equal(token_normalization, "lemmatization") ~ "Lemma",
            str_equal(token_normalization, "stemming") ~ "Stem"
        ),
        stopword_removal = case_when(
            stopword_removal ~ "Yes",
            !stopword_removal ~ "No"
        ),
        trimming = case_when(
            trimming ~ "Yes",
            !trimming ~ "No"
        ),
        alternative_model = case_when(
            alternative_model ~ "Yes",
            !alternative_model ~ "No"
        )
    ) |>
    rename(
        "Tok. Norm." = token_normalization,
        "Stopword Rem." = stopword_removal,
        "Trim." = trimming,
        "Alt. Model" = alternative_model,
        "k" = k_setting,
        "Iter." = iteration_setting
    ) |>
    gather(key, value, all_of(choices)) |>
    mutate(key = factor(key, levels = choices)) |>
    ggplot(aes(x = specifications, y = value, color = color)) +
    geom_point(aes(x = specifications, y = value), shape = 124, size = 3.35) +
    scale_color_identity() +
    theme_minimal() +
    facet_grid(key ~ 1, scales = "free_y", space = "free_y") +
    theme(
        axis.line = element_line("black", linewidth = 0.5),
        legend.position = "none",
        panel.spacing = unit(0.75, "lines"),
        axis.text = element_text(colour = "black"),
        strip.text.x = element_blank(),
        strip.text.y = element_text(angle = 0)
    ) +
    labs(x = "", y = "")

plot <- plot_grid(
    plot_a,
    plot_b,
    labels = c("A", "B"),
    align = "v",
    axis = "rbl",
    rel_heights = c(2, 3),
    ncol = 1
)
