library(here)

results <- read.csv(here("results", "aggregated", "takano", "1.csv"))
tmmv.plot_spec_curve(results)
