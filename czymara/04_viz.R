library(here)

results <- read.csv(here("results", "aggregated", "czymara", "1.csv"))
tmmv.plot_spec_curve(results)
