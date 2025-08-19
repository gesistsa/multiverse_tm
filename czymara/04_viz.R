library(here)

slug <- "czymara"

results <- read.csv(here("results", "aggregated", slug, "1.csv"))
tmmv.plot_spec_curve(results, tmmv.data[[slug]])
