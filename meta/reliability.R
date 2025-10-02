library(here)
library(ggplot2)
library(ggridges)

generate_density <- function(slug) {
    thetas <- tmmv.read_thetas(slug)
    hashes <- names(thetas[[1]])
    all_iccs <- hashes |>
        purrr::map_dbl(
            \(x) thetas |> purrr::map(x) |> tmmv.calculate_icc(),
            .progress = TRUE
        )
    return(data.frame(slug = slug, icc = all_iccs))
}

all_density <- purrr::map(
    c("chan", "curini", "czymara", "jankin", "takano", "tvinnereim"),
    generate_density
) |>
    purrr::list_rbind()

## the figure is sort of misleading; but we can work on it later

all_density |>
    dplyr::rename(study = slug) |>
    ggplot(aes(x = icc)) +
    geom_histogram(bins = 30) +
    facet_grid(cols = vars(study)) +
    ggplot2::theme_minimal() -> fig

ggsave(here::here("plots", "meta_icc.pdf"), fig, width = 9, height = 4)

## geom_density_ridges(alpha = 0.5)
