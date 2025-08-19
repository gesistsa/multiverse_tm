# Some of the code for plotting is adapted from the specr R package
# (https://github.com/masurp/specr).
# The original code is under a GPL-3 license:
# https://www.gnu.org/licenses/gpl-3.0.html.
# The original authors are:
#   -Philipp K. Masur
#   -M. Scharkow
# The citation is:
#   Masur, Philipp K. & Scharkow, M. (2020). specr: Conducting and Visualizing
#   Specification Curve Analyses.
#   Available from https://CRAN.R-project.org/package=specr

#library(cowplot)
#library(dplyr)
#library(ggplot2)
# library("here")
#library(stringr)
#library(tidyr)

tmmv.plot_spec_curve <- function(results) {
    plot_a <- results |>
        dplyr::arrange(Estimate) |>
        dplyr::mutate(
            specifications = seq_len(nrow(results)),
            color = dplyr::case_when(
                Q2.5 > 0 ~ tmmv.colors[["orange"]],
                Q97.5 < 0 ~ tmmv.colors[["lightblue"]],
                is.na(Estimate) ~ tmmv.colors[["berrypurple"]],
                TRUE ~ "grey"
            )
        ) |>
        ggplot2::ggplot(ggplot2::aes(
            x = specifications,
            y = Estimate,
            ymin = Q2.5,
            ymax = Q97.5,
            color = color
        )) +
        ggplot2::geom_point(ggplot2::aes(color = color), size = 1) +
        ggplot2::theme_minimal() +
        ggplot2::scale_color_identity() +
        ggplot2::theme(
            strip.text = ggplot2::element_blank(),
            axis.line = ggplot2::element_line("black", linewidth = .5),
            legend.position = "none",
            panel.spacing = grid::unit(0.75, "lines"),
            axis.text = ggplot2::element_text(colour = "black")
        ) +
        ggplot2::labs(x = "", y = "Median [95% Cr. I.]") +
        ggplot2::geom_pointrange(alpha = 0.5, size = 0.6, fatten = 1) +
        ggplot2::geom_hline(
            yintercept = 0,
            colour = "black",
            linetype = "dotted"
        )

    value <- key <- NULL
    choices <- c(
        "Tok. Norm.",
        "Stopword Rem.",
        "Trim.",
        "Alt. Model",
        "k",
        "Iter."
    )

    # Todo: Panel B of the entire plot still displays k and iteration settings as
    # 1, 2, 3. I suppose that this should actually display the actual values used.
    plot_b <- results |>
        dplyr::arrange(Estimate) |>
        dplyr::mutate(
            specifications = seq_len(nrow(results)),
            color = dplyr::case_when(
                Q2.5 > 0 ~ tmmv.colors[["orange"]],
                Q97.5 < 0 ~ tmmv.colors[["lightblue"]],
                is.na(Estimate) ~ tmmv.colors[["berrypurple"]],
                TRUE ~ "grey"
            )
        ) |>
        dplyr::mutate(
            token_normalization = dplyr::case_when(
                stringr::str_equal(token_normalization, "none") ~ "None",
                stringr::str_equal(token_normalization, "lemmatization") ~
                    "Lemma",
                stringr::str_equal(token_normalization, "stemming") ~ "Stem"
            ),
            stopword_removal = dplyr::case_when(
                stopword_removal ~ "Yes",
                !stopword_removal ~ "No"
            ),
            trimming = dplyr::case_when(
                trimming ~ "Yes",
                !trimming ~ "No"
            ),
            alternative_model = dplyr::case_when(
                alternative_model ~ "Yes",
                !alternative_model ~ "No"
            )
        ) |>
        dplyr::rename(
            "Tok. Norm." = token_normalization,
            "Stopword Rem." = stopword_removal,
            "Trim." = trimming,
            "Alt. Model" = alternative_model,
            "k" = k_setting,
            "Iter." = iteration_setting
        ) |>
        tidyr::gather(key, value, all_of(choices)) |>
        dplyr::mutate(key = factor(key, levels = choices)) |>
        ggplot2::ggplot(ggplot2::aes(
            x = specifications,
            y = value,
            color = color
        )) +
        ggplot2::geom_point(
            ggplot2::aes(x = specifications, y = value),
            shape = 124,
            size = 3.35
        ) +
        ggplot2::scale_color_identity() +
        ggplot2::theme_minimal() +
        ggplot2::facet_grid(key ~ 1, scales = "free_y", space = "free_y") +
        ggplot2::theme(
            axis.line = ggplot2::element_line("black", linewidth = 0.5),
            legend.position = "none",
            panel.spacing = grid::unit(0.75, "lines"),
            axis.text = ggplot2::element_text(colour = "black"),
            strip.text.x = ggplot2::element_blank(),
            strip.text.y = ggplot2::element_text(angle = 0)
        ) +
        ggplot2::labs(x = "", y = "")

    cowplot::plot_grid(
        plot_a,
        plot_b,
        labels = c("A", "B"),
        align = "v",
        axis = "rbl",
        rel_heights = c(2, 3),
        ncol = 1
    )
}
