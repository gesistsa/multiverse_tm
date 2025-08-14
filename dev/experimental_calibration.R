theta_df <- read.csv(here(
    "intermediate",
    "tvinnereim",
    "runs",
    "1",
    "theta",
    "anchor_by_original_setting.csv"
))

anchor_setting <- list()
anchor_setting$token_normalization <- "stemming"
anchor_setting$stopword_removal <- TRUE
anchor_setting$trimming <- TRUE
anchor_setting$alternative_model <- FALSE
anchor_setting$k_setting <- 1
anchor_setting$iteration_setting <- 1

library(ggplot2)

plot_calibration <- function(theta_df, anchor_setting) {
    anchor_theta <- theta_df[, rlang::hash(anchor_setting)]

    q25 <- apply(theta_df[order(anchor_theta), ], 1, quantile)[2, ]
    q75 <- apply(theta_df[order(anchor_theta), ], 1, quantile)[4, ]

    expected_value <- sort(anchor_theta)
    data.frame(i = seq_along(expected_value), expected_value, q25, q75) |>
        ggplot(aes(x = i, y = expected_value)) +
        geom_line(linewidth = 1) +
        geom_ribbon(aes(ymin = q25, ymax = q75), alpha = 0.1) +
        ggtitle("theta") +
        theme_minimal()
}

plot_calibration(theta_df, anchor_setting)

plot_hosmer_lemeshow <- function(theta_df, anchor_setting, slug = "theta") {
    available_hashes <- colnames(theta_df) |> gsub("^X", "", x = _)

    anchor_theta <- theta_df[, available_hashes == rlang::hash(anchor_setting)]
    decile_gp <- as.numeric(cut(
        anchor_theta,
        quantile(anchor_theta, probs = seq(0, 1, 0.1))
    ))
    split_theta <- split(theta_df, decile_gp)

    decile_q25 <- purrr::map_dbl(split_theta, \(x) quantile(unlist(x), 0.25))

    decile_q75 <- purrr::map_dbl(split_theta, \(x) quantile(unlist(x), 0.75))

    data.frame(
        i = seq_along(decile_q25),
        expected_value = tapply(anchor_theta, decile_gp, mean),
        q25 = decile_q25,
        q75 = decile_q75
    ) |>
        ggplot(aes(x = i, y = expected_value)) +
        geom_line(linewidth = 1) +
        geom_point(size = 5) +
        geom_ribbon(aes(ymin = q25, ymax = q75), alpha = 0.1) +
        ggtitle(slug) +
        theme_minimal()
}

theta_df <- read.csv(here(
    "intermediate",
    "czymara",
    "runs",
    "1",
    "theta",
    "anchor_by_original_setting.csv"
))
anchor_setting <- list()
anchor_setting$token_normalization <- "stemming"
anchor_setting$stopword_removal <- TRUE
anchor_setting$trimming <- TRUE
anchor_setting$alternative_model <- FALSE
anchor_setting$k_setting <- 1
anchor_setting$iteration_setting <- 1

plot_hosmer_lemeshow(theta_df, anchor_setting, "czymara")

theta_df <- read.csv(here(
    "intermediate",
    "takano",
    "runs",
    "1",
    "theta",
    "anchor_by_original_setting.csv"
))

anchor_setting <- list()
anchor_setting$token_normalization <- "lemmatization"
anchor_setting$stopword_removal <- TRUE
anchor_setting$trimming <- TRUE
anchor_setting$alternative_model <- FALSE
anchor_setting$k_setting <- 1
anchor_setting$iteration_setting <- 1

plot_hosmer_lemeshow(theta_df, anchor_setting, "takano")
