library(here)
library(dplyr)
library(ggplot2)

thetas <- readRDS(here(
    "intermediate",
    "chan",
    "runs",
    "1",
    "theta",
    "theta.RDS"
))

chan_df <- thetas |> purrr::map(as.data.frame) |> purrr::list_cbind()

## colnames(theta_df) <- names(thetas)
## pca <- prcomp(theta_df, scale = TRUE)

## eigenvalues <- pca$sdev^2

## plot(eigenvalues[1:10], type = "b", xlab = "Principal Component", ylab = "Eigenvalue")

get_theta_by_topic_name <- function(topic_name, theta) {
    topic_index <- which(stringr::str_detect(
        colnames(theta),
        topic_name
    ))
    if (identical(topic_index, integer(0))) {
        return(rep(0, nrow(theta)))
    }
    return(theta[, topic_index, drop = TRUE])
}

get_theta_curini <- function(setting) {
    mod <- readRDS(file.path(
        here::here("intermediate", "curini", "runs", "1"),
        paste0(rlang::hash(setting), ".RDS")
    ))

    theta <- rep(0, nrow(mod$mod$theta) * 3) |>
        matrix(ncol = 3) |>
        as.data.frame()

    colnames(theta) <- c("multilateralism", "humanitarian_dimension", "war")

    for (cnames in colnames(theta)) {
        theta[, cnames] <- get_theta_by_topic_name(cnames, mod$mod$theta)
    }
    reg_data <- cbind(theta)

    ## from the original stata code

    # gen multi100 = multilateralism/(multilateralism+humanitarian_dimensio+war)
    # gen humi100 = humanitarian_dimensio/(multilateralism+humanitarian_dimensio+war)
    # gen war100 = war/(multilateralism+humanitarian_dimensio+war)

    reg_data <- reg_data |>
        mutate(
            t3 = multilateralism + humanitarian_dimension + war,
            multi100 = multilateralism / t3,
            humi100 = humanitarian_dimension / t3,
            war100 = war / t3
        ) |>
        select(-t3)
    return(select(reg_data, multi100))
}

settings <- tmmv.get_settings(full = TRUE)

curini_df <- purrr::map(settings, get_theta_curini) |> purrr::list_cbind()


multiverse <- readRDS(here(
    "intermediate",
    "jankin",
    "runs",
    "1",
    "theta",
    "theta.RDS"
))

jankin_df <- purrr::map(multiverse, \(x) get_theta_by_topic_name("SDG16", x)) |>
    purrr::map(as.data.frame) |>
    purrr::list_cbind()

get_pca <- function(df, slug) {
    pca <- prcomp(df, scale = TRUE)
    eigenvalues <- pca$sdev^2
    data.frame(
        slug = slug,
        i = seq_along(eigenvalues),
        eigenvalue = eigenvalues
    )
}

pca_combined <- purrr::map2(
    list(chan_df, curini_df, jankin_df),
    c("chan", "curini", "jankin"),
    get_pca
) |>
    purrr::list_rbind()

filter(pca_combined, i <= 10) |>
    ggplot(aes(x = i, y = eigenvalue, color = slug)) +
    geom_line(size = 1)
