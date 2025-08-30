library(here)
library(dplyr)
library(ggplot2)

## because takano doesn't have the same size
## we weight it so that the max eigenvalue is comparable
calculate_pca <- function(slug, multiverse_size = 216) {
    .f <- function(run, thetas, slug, multiverse_size = 216) {
        df <- as.data.frame(thetas[[run]])
        pca <- prcomp(df, scale = TRUE)
        weight <- multiverse_size / ncol(df)
        eigenvalues <- (pca$sdev^2) * weight
        data.frame(
            slug = slug,
            run = run,
            i = seq_along(eigenvalues),
            eigenvalue = round(eigenvalues, 5)
        )
    }
    thetas <- tmmv.read_thetas(slug)
    purrr::map(seq_along(thetas), .f = .f, thetas = thetas, slug = slug) |>
        purrr::list_rbind()
}

combined_pca <- purrr::map(names(tmmv.data), calculate_pca) |>
    purrr::list_rbind()

dplyr::filter(combined_pca, i <= 10) |>
    ggplot(aes(x = i, y = eigenvalue, color = slug)) +
    geom_line(linewidth = 1) +
    scale_color_manual(values = as.character(tmmv.palette_safe)) +
    facet_grid(cols = vars(run)) +
    ggplot2::theme_minimal()
