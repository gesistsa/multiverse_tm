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
ggplot(all_density, aes(x = icc, y = slug)) +
    geom_density_ridges(alpha = 0.5)
