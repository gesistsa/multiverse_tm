library(here)

slug <- "takano"

results <- read.csv(here("results", "aggregated", slug, "1.csv"))
tmmv.plot_spec_curve(results, anchor = tmmv.data[[slug]]$anchor)
