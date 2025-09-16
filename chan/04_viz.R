## no commandline interface (yet); because we might do it on overleaf

library(here)
library(dplyr)
library(ggplot2)

slug <- "chan"

purrr::map(1:3, \(x) {
    read.csv(here("results", "aggregated", slug, paste0(x, ".csv")))
}) |>
    tmmv.plot_spec_curve(tmmv.data[[slug]])
