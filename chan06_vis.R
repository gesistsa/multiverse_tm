## no commandline interface (yet); because we might do it on overleaf

library(here)
library(dplyr)
library(ggplot2)

## TODO: aggregated multiple runs
overall <- read.csv(here("results", "aggregated", "chan", "1.csv"))

## note that we need to add one to K (the keyworded topic)
overall |> arrange(Estimate) |>
    mutate(Model =
               if_else(alternative_model, "SeededLDA", "keyATM")) |>
    mutate(k_setting = case_match(k_setting,
                                  1 ~ "K = 40",
                                  2 ~ "K = 36",
                                  3 ~ "K = 44")) |> 
    mutate(rank = row_number()) |>
    ggplot(aes(x = rank, y = Estimate, color = Model)) +
    geom_point(size = 0.5) +
    geom_linerange(aes(ymin = Q2.5, ymax = Q97.5), size=0.5) +
    facet_wrap(~k_setting) +
    ylim(-1, 6) +
    theme_minimal() +
    theme(legend.position = "bottom", plot.background = element_rect(colour = "white")) +
    scale_color_manual(values  = c("#642878", "#F08741"))

# ggsave(here("plots/chan_brms.png"), width = 2500, height = 1080, units = "px")



### Here is another visualisation.

# Some of the code for plotting is adapted from the specr R package
# (https://github.com/masurp/specr).
# The original code is under a GPL-3 license:
# https://www.gnu.org/licenses/gpl-3.0.html.
# The original authors are:
#   -Philipp K. Masur
#   -M. Scharkow
# The citation is:
#   Masur, Philipp K. & Scharkow, M. (2020). specr: Conducting and Visualizing
#   Specification Curve Analyses.
#   Available from https://CRAN.R-project.org/package=specr

library("cowplot")
# library("dplyr")
# library("ggplot2")
# library("here")
library("stringr")
library("tidyr")

results <- read.csv(here("results", "aggregated", "chan", "1.csv"))

plot_a <- results |>
    arrange(Estimate) |>
    mutate(specifications = 1:nrow(results),
           color = case_when(Q2.5 > 0 ~ "green",
                             Q97.5 < 0 ~ "#377eb8",
                             is.na(Estimate) ~ "#e41a1c",
                             TRUE ~ "darkgrey")) |>
    ggplot(aes(x = specifications,
               y = Estimate,
               ymin = Q2.5,
               ymax = Q97.5,
               color = color)) +
    geom_point(aes(color = color),
               size = 1) +
    theme_minimal() +
    scale_color_identity() +
    theme(strip.text = element_blank(),
          axis.line = element_line("black", linewidth = .5),
          legend.position = "none",
          panel.spacing = unit(0.75, "lines"),
          axis.text = element_text(colour = "black")) +
    labs(x = "",
         y = "Median [95% Cr. I.]") +
    geom_pointrange(alpha = 0.5,
                    size = 0.6,
                    fatten = 1) +
    geom_hline(yintercept = 0,
               colour = "black",
               linetype = "dotted")

value <- key <- NULL
choices = c("Tok. Norm.", "Stopword Rem.", "Trim.", "Alt. Model",
            "k", "Iter.")

# Todo: Panel B of the entire plot still displays k and iteration settings as
# 1, 2, 3. I suppose that this should actually display the actual values used.
plot_b <- results |>
    arrange(Estimate) |>
    mutate(specifications = 1:nrow(results),
           color = case_when(Q2.5 > 0 ~ "green",
                             Q97.5 < 0 ~ "#377eb8",
                             is.na(Estimate) ~ "#e41a1c",
                             TRUE ~ "darkgrey")) |>
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
    rename("Tok. Norm." = token_normalization,
           "Stopword Rem." = stopword_removal,
           "Trim." = trimming,
           "Alt. Model" = alternative_model,
           "k" = k_setting,
           "Iter." = iteration_setting) |>
    gather(key, value, all_of(choices)) |>
    mutate(key = factor(key, levels = choices)) |>
    ggplot(aes(x = specifications,
               y = value,
               color = color)) +
    geom_point(aes(x = specifications,
                   y = value),
               shape = 124,
               size = 3.35) +
    scale_color_identity() +
    theme_minimal() +
    facet_grid(key~1, scales = "free_y", space = "free_y") +
    theme(
        axis.line = element_line("black", linewidth = 0.5),
        legend.position = "none",
        panel.spacing = unit(0.75, "lines"),
        axis.text = element_text(colour = "black"),
        strip.text.x = element_blank(),
        strip.text.y = element_text(angle = 0)) +
    labs(x = "", y = "")

plot <- plot_grid(plot_a,
                  plot_b,
                  labels = c("A", "B"),
                  align = "v",
                  axis = "rbl",
                  rel_heights = c(2, 3),
                  ncol = 1)

# ggsave(filename = here("plots/chan_brms_v2.pdf"),
#        plot = plot,
#        width = (210 - 2 * 25.4) * 2,
#        height = (297 - 2 * 25.4) * (2 / 3) * 2,
#        units = "mm")
