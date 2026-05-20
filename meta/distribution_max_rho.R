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

max_rho <- setdiff(names(tmmv.data), c("jankin", "curini", "chan")) |>
    purrr::map(.f) |>
    purrr::list_rbind() |>
    dplyr::select(slug, max_rho)

fig <- ggplot(max_rho, aes(max_rho)) +
    geom_histogram(bins = 30) +
    facet_grid(rows = vars(slug), scales = "free") +
    ylab("Count") +
    xlab(bquote(max(rho))) +
    ggplot2::theme_minimal()

ggplot2::ggsave(
    filename = here::here("plots", "meta_distribution_max_rho.pdf"),
    plot = fig,
    width = 8,
    height = 10
)
