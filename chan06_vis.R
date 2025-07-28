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
