library(here)
library(ggplot2)
library(ggridges)

read_theta <- function(slug) {}

slug <- "takano"
run <- 1

read_thetas <- function(slug) {
    .f <- function(run, slug) {
        path <- here("intermediate", slug, "runs", run, "theta/theta.RDS")
        if (fs::file_exists(path)) {
            return(readRDS(path))
        }
        NULL
    }
    purrr::map(c(1, 2, 3), .f = .f, slug = slug)
}

thetas <- read_thetas("tvinnereim")

hashes <- names(thetas[[1]])

all_iccs <- hashes |>
    purrr::map_dbl(
        \(x) thetas |> purrr::map(x) |> tmmv.calculate_icc(),
        .progress = TRUE
    )

generate_density <- function(slug) {
    thetas <- read_thetas(slug)
    hashes <- names(thetas[[1]])
    all_iccs <- hashes |>
        purrr::map_dbl(
            \(x) thetas |> purrr::map(x) |> tmmv.calculate_icc(),
            .progress = TRUE
        )
    return(data.frame(slug = slug, icc = all_iccs))
}

all_density <- purrr::map(
    c("curini", "czymara", "takano", "tvinnereim"),
    generate_density
) |>
    purrr::list_rbind()

ggplot(all_density, aes(x = icc, y = slug)) +
    geom_density_ridges(stat = "binline", alpha = 0.5, scale = 1, bins = 50)
