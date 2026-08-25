library(here)
library(dplyr)
library(ggplot2)
library(cowplot)
library(stringr)
library(tidyr)
library(purrr)

slug <- "curini"

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

ggsave(
    here::here("plots", paste0(slug, "_spec.jpg")),
    f,
    width = 8,
    height = 10,
    bg = "white",
    unit = "in",
    dpi = 600
)


## conditional effect plot

.r <- function(i, slug) {
    condit_effect <- read.csv(here::here(
        "results",
        "aggregated",
        slug,
        paste0("condit_", i, ".csv")
    ))
    condit_effect$i <- i
    condit_effect$id <- paste0(condit_effect$i, "_", condit_effect$hash)
    return(condit_effect)
}

condit_effect <- purrr::map(1:3, .r, slug = slug) |> purrr::list_rbind()

curini_hash <- rlang::hash(tmmv.data$curini$anchor)

## condit_effect$alpha <- ifelse(condit_effect$hash == curini_hash, 1, 0.05)

condit_effect |>
    ggplot(aes(x = LR, y = pred_multi100, group = id)) +
    geom_line(alpha = 0.05) +
    geom_line(
        data = condit_effect[
            condit_effect$hash == rlang::hash(tmmv.data$curini$anchor),
        ],
        color = tmmv.palette_safe$vermilion,
        linewidth = 0.8,
    ) +

    xlab("Left-right alignment") +
    ylab("Topic proportion") +
    theme_minimal() -> f

ggsave(
    here::here("plots", paste0(slug, "_spaghetti.pdf")),
    f,
    width = 8,
    height = 10
)

ggsave(
    here::here("plots", paste0(slug, "_spaghetti.jpg")),
    f,
    width = 8,
    height = 10,
    units = "in",
    bg = "white",
    dpi = 600
)
