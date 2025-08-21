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

tmmv.plot_spec_curve <- function(
    results,
    metadata = NULL,
    anchor = NULL,
    ylab = "Estimate [95% Conf. I.]",
    k = NULL,
    model_names = NULL
) {
    .process_data_plot_spec_curve <- function(results, anchor) {
        output <- list() # should have results_plotting, results, axis_breaks, axis_labels
        if (is.data.frame(results)) {
            output$results_plotting <- results |>
                dplyr::arrange(Estimate) |>
                dplyr::mutate(specification = seq_len(nrow(results)))
            if (!is.null(anchor)) {
                output$results_plotting <- output$results_plotting |>
                    dplyr::mutate(
                        anchor = token_normalization ==
                            anchor$token_normalization &
                            stopword_removal == anchor$stopword_removal &
                            trimming == anchor$stopword_removal &
                            alternative_model == anchor$alternative_model &
                            k_setting == anchor$k_setting &
                            iteration_setting == anchor$iteration_setting
                    )
                output$axis_breaks <- which(output$results_plotting$anchor)
                output$axis_labels <- c("Original")
            } else {
                output$results_plotting <- output$results_plotting |>
                    dplyr::mutate(anchor = FALSE)
                output$axis_breaks <- NULL
                output$axis_labels <- NULL
            }
            output$results <- results
            return(output)
        }

        ## assumed to be list of dfs (replications) from now on

        specification_order <- purrr::map(results, \(x) x$Estimate) |>
            purrr::list_c() |>
            matrix(ncol = length(results), byrow = FALSE) |>
            apply(1, mean) |>
            rank()

        for (i in seq_along(results)) {
            results[[i]]$specification <- specification_order
        }

        if (!is.null(anchor)) {
            for (i in seq_along(results)) {
                results[[i]] <- results[[i]] |>
                    dplyr::mutate(
                        anchor = token_normalization ==
                            anchor$token_normalization &
                            stopword_removal == anchor$stopword_removal &
                            trimming == anchor$stopword_removal &
                            alternative_model == anchor$alternative_model &
                            k_setting == anchor$k_setting &
                            iteration_setting == anchor$iteration_setting
                    )
            }
            output$axis_breaks <- results[[1]]$specification[which(
                results[[1]]$anchor
            )]
            output$axis_labels <- c("Original")
        } else {
            for (i in seq_along(results)) {
                results[[i]]$anchor <- FALSE
            }
            output$axis_breaks <- NULL
            output$axis_labels <- NULL
        }
        output$results_plotting <- purrr::list_rbind(results)
        output$results <- results
        return(output)
    }

    if (!is.null(metadata)) {
        if (metadata$keyword) {
            keyworded_k <- length(metadata$dict)
        } else {
            keyworded_k <- 0
        }
        k <- metadata$k + keyworded_k
        model_names <- c(metadata$alternative_model, metadata$original_model)
        anchor <- metadata$anchor
    }
    if (is.null(k)) {
        k <- c(1, 2, 3)
    }
    if (is.null(model_names)) {
        model_names <- c("Alt.", "Orig.")
    }
    processed_data <- .process_data_plot_spec_curve(results, anchor)
    plot_a <- processed_data$results_plotting |>
        dplyr::mutate(
            color = dplyr::case_when(
                Q2.5 > 0 ~ tmmv.colors[["orange"]],
                Q97.5 < 0 ~ tmmv.colors[["lightblue"]],
                is.na(Estimate) ~ tmmv.colors[["berrypurple"]],
                TRUE ~ "darkgrey"
            ),
            alpha = ifelse(anchor, 0.9, 0.2)
        ) |>
        ggplot2::ggplot(ggplot2::aes(
            x = specification,
            y = Estimate,
            ymin = Q2.5,
            ymax = Q97.5,
            color = color,
            alpha = alpha
        )) +
        ggplot2::geom_point(
            ggplot2::aes(color = color, alpha = alpha),
            size = 1
        ) +
        ggplot2::scale_color_identity() +
        ggplot2::labs(x = "", y = ylab) +
        ggplot2::geom_pointrange(
            ggplot2::aes(alpha = alpha),
            size = 0.6,
            fatten = 1
        ) +
        ggplot2::scale_alpha_identity() +
        ggplot2::geom_hline(
            yintercept = 0,
            colour = "black",
            linetype = "dotted"
        ) +
        ggplot2::scale_x_continuous(
            breaks = processed_data$axis_breaks,
            labels = processed_data$axis_labels
        ) +
        ggplot2::theme_minimal() +
        ggplot2::theme(
            strip.text = ggplot2::element_blank(),
            axis.line = ggplot2::element_line("black", linewidth = .5),
            legend.position = "none",
            panel.spacing = grid::unit(0.75, "lines"),
            axis.text = ggplot2::element_text(colour = "black")
        )

    value <- key <- NULL
    choices <- c(
        "Tok. Norm.",
        "Stopword Rem.",
        "Trim.",
        "Model",
        "k",
        "Iter."
    )

    # Todo: Panel B of the entire plot still displays k and iteration settings as
    # 1, 2, 3. I suppose that this should actually display the actual values used.
    if (is.data.frame(results)) {
        results_plotting_b <- processed_data$results_plotting
    } else {
        results_plotting_b <- processed_data$results[[1]] |>
            dplyr::select(-anchor)
    }
    plot_b <- results_plotting_b |>
        dplyr::mutate(
            color = dplyr::case_when(
                Q2.5 > 0 ~ tmmv.colors[["orange"]],
                Q97.5 < 0 ~ tmmv.colors[["lightblue"]],
                is.na(Estimate) ~ tmmv.colors[["berrypurple"]],
                TRUE ~ "darkgrey"
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
                alternative_model ~ model_names[1],
                !alternative_model ~ model_names[2]
            ),
            iteration_setting = dplyr::case_when(
                iteration_setting == 1 ~ "±0%",
                iteration_setting == 2 ~ "-20%",
                iteration_setting == 3 ~ "+20%"
            ),
            k_setting = k[k_setting]
        ) |>
        dplyr::rename(
            "Tok. Norm." = token_normalization,
            "Stopword Rem." = stopword_removal,
            "Trim." = trimming,
            "Model" = alternative_model,
            "k" = k_setting,
            "Iter." = iteration_setting
        ) |>
        tidyr::gather(key, value, all_of(choices)) |>
        dplyr::mutate(key = factor(key, levels = choices)) |>
        ggplot2::ggplot(ggplot2::aes(
            x = specification,
            y = value,
            color = color
        )) +
        ggplot2::geom_point(
            ggplot2::aes(x = specification, y = value),
            shape = 124,
            size = 3.35
        ) +
        ggplot2::scale_color_identity() +
        ggplot2::scale_x_continuous(
            breaks = processed_data$axis_breaks,
            labels = processed_data$axis_labels
        ) +
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
