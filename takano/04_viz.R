library(here)

slug <- "takano"

## read.csv(here("results", "aggregated", slug, "1.csv")) |>
##     tmmv.plot_spec_curve(tmmv.data[[slug]])

purrr::map(1:3, \(x) {
    read.csv(here("results", "aggregated", slug, paste0(x, ".csv")))
}) |>
    tmmv.plot_spec_curve(tmmv.data[[slug]]) -> f

ggsave(
    here::here("plots", paste0(slug, "_spec.pdf")),
    f,
    width = 8,
    height = 10
)
