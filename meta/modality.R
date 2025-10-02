library(dplyr)
library(purrr)
library(ggplot2)
library(here)

.f <- function(slug) {
    raw_estimates <- purrr::map(1:3, \(x) {
        read.csv(here("results", "aggregated", slug, paste0(x, ".csv")))
    }) |>
        purrr::list_rbind()
    raw_estimates$slug <- slug
    return(raw_estimates)
}

estimates <- setdiff(names(tmmv.data), "jankin") |>
    purrr::map(.f) |>
    purrr::list_rbind() |>
    dplyr::select(slug, Estimate)

fig <- ggplot(estimates, aes(Estimate)) +
    geom_histogram(bins = 30) +
    facet_grid(cols = vars(slug), scales = "free") +
    ggplot2::theme_minimal()

ggsave(here::here("plots", "meta_density.pdf"), fig, width = 8, height = 4)
