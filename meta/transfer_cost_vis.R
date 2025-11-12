library(purrr)
library(ggplot2)

.read_cost <- function(slug) {
    output <- readRDS(here::here("results", "cost", slug, "1.RDS"))
    data.frame(slug = slug, EMD = output$result$cost)
}

cost_df <- c("czymara", "takano", "tvinnereim") |>
    purrr::map(.read_cost) |>
    purrr::list_rbind()

fig <- ggplot(cost_df, aes(EMD)) +
    geom_histogram(bins = 30) +
    facet_grid(rows = vars(slug)) +
    ylab("Count") +
    ggplot2::theme_minimal()

ggsave(here::here("plots", "meta_cost.pdf"), fig, width = 5, height = 4)

## str(output)

## colnames(output$result) <- c("i", "j", "weight")
## library(igraph)
## g <- graph_from_data_frame(output$result, directed = FALSE)
## ecc <- eccentricity(g)
## radius(g)
## diameter(g)

## output$settings |> purrr::map(as.data.frame) |> purrr::list_rbind() |> cbind(data.frame(Estimate = ecc, Q2.5 = ecc, Q97.5 = ecc)) |> tmmv.plot_spec_curve(tmmv.data[[args$slug]])
