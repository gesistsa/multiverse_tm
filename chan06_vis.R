## no commandline interface (yet); because we might do it on overleaf

library(here)
library(dplyr)
library(ggplot2)

## TODO: aggregated multiple runs
overall <- read.csv(here("results", "aggregated", "chan", "1.csv"))

## note that we need to add one to K (the keyworded topic)
overall |> arrange(Estimate) |>
    mutate(alternative_model =
               if_else(alternative_model, "Seeded", "keyATM")) |>
    mutate(k_setting = case_match(k_setting,
                                  1 ~ "K = 40",
                                  2 ~ "K = 36",
                                  3 ~ "K = 44")) |> 
    mutate(rank = row_number()) |>
    ggplot(aes(x = rank, y = Estimate)) +
    geom_point() +
    geom_linerange(aes(ymin = Q2.5, ymax = Q97.5)) +
    facet_grid(rows = vars(alternative_model),
               cols = vars(k_setting)) +
    ylim(-1, 6) +
    theme_minimal()
