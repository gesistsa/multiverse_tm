library(here)
library(dplyr)
library(purrr)
library(effectsize)
library(ggplot2)

.calculate <- function(slug) {
    raw_estimates <- purrr::map(1:3, \(x) {
        read.csv(here("results", "aggregated", slug, paste0(x, ".csv")))
    }) |>
        purrr::list_rbind()

    mod <- raw_estimates |>
        dplyr::mutate(
            k_setting = as.factor(k_setting),
            iteration_setting = as.factor(iteration_setting),
            Estimate = (Estimate - mean(Estimate) / sd(Estimate))
        ) |>
        lm(
            Estimate ~
                token_normalization +
                    stopword_removal +
                    trimming +
                    alternative_model +
                    k_setting +
                    iteration_setting,
            data = _
        )

    mod_eta2 <- mod |>
        effectsize::eta_squared(
            generalized = FALSE,
            partial = FALSE,
            alternative = "two.sided"
        ) |>
        as.data.frame() |>
        dplyr::select(Parameter, Eta2)

    mod_summary <- mod |> summary()
    unexplained_variance <- 1 - mod_summary$r.squared

    output <- rbind(
        data.frame(Parameter = "Unexplained", Eta2 = unexplained_variance),
        mod_eta2
    ) |>
        arrange(Eta2)
    output$slug <- slug
    return(output)
}

variance_decomposition <- setdiff(names(tmmv.data), "jankin") |>
    purrr::map(.calculate) |>
    purrr::list_rbind() |>
    mutate(
        Parameter = recode(
            Parameter,
            "trimming" = "Trimming",
            "token_normalization" = "Token normalization",
            "stopword_removal" = "Stopword removal",
            "iteration_setting" = "Iteration",
            "k_setting" = "K",
            "alternative_model" = "Algorithm"
        )
    )


fig <- variance_decomposition |>
    ggplot(aes(x = Eta2, y = Parameter)) +
    geom_bar(stat = "identity") +
    facet_grid(rows = vars(slug)) +
    xlab("Variance explained") +
    ggplot2::theme_minimal()

ggplot2::ggsave(
    filename = here::here("plots", "meta_variance_decomposition.pdf"),
    plot = fig,
    width = 8,
    height = 10
)
