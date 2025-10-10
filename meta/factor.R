library(here)
library(dplyr)
library(ggplot2)

## because takano doesn't have the same size
## we weight it so that the max eigenvalue is comparable; 648 = 216 * 3 runs
calculate_pca <- function(slug, multiverse_size = 648) {
    df <- tmmv.read_thetas(slug) |>
        purrr::map(as.data.frame) |>
        purrr::list_cbind()
    pca <- prcomp(df, scale = TRUE)
    weight <- multiverse_size / ncol(df)
    eigenvalues <- (pca$sdev^2) * weight
    data.frame(
        slug = slug,
        i = seq_along(eigenvalues),
        eigenvalue = round(eigenvalues, 5)
    )
}

combined_pca <- purrr::map(names(tmmv.data), calculate_pca) |>
    purrr::list_rbind()

f <- dplyr::filter(combined_pca, i <= 10) |>
    dplyr::rename(study = slug, rank = i) |>
    ggplot(aes(x = rank, y = eigenvalue, color = study)) +
    geom_line(linewidth = 1) +
    scale_color_manual(values = as.character(tmmv.palette_safe)) +
    scale_x_continuous(breaks = seq(1, 10, 1)) +
    xlab("Rank") +
    ylab("Eigenvalue") +
    ggplot2::theme_minimal()

ggsave(
    here::here("plots", "meta_pca.pdf"),
    f,
    width = 8,
    height = 8
)
