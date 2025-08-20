library(here)

slug <- "takano"

results <- read.csv(here("results", "aggregated", slug, "1.csv"))
tmmv.plot_spec_curve(results, tmmv.data[[slug]])

results <- purrr::map(1:3, \(x) {
    read.csv(here("results", "aggregated", slug, paste0(x, ".csv")))
})
tmmv.plot_spec_curve(results, tmmv.data[[slug]])
