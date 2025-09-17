library(here)
library(ggplot2)
library(dplyr)
library(tidyr)
library(purrr)

# Restore meta data
settings <- tmmv.get_settings()
names(settings) <- map_chr(settings, rlang::hash)

dfm_filenames <- unique(map_chr(settings, \(x) rlang::hash(x[1:3])))

dfms <- dfm_filenames |>
    set_names() |>
    map(
        \(x) {
            dfm_filename <- paste0(x, ".RDS")
            dfm <- readRDS(here("intermediate", "jankin", dfm_filename))
            return(quanteda::docvars(dfm, "Year"))
        }
    )


reformat_theta_matrix <- function(x, setting_hash) {
    x <- as.data.frame(x)
    colnames(x) <- gsub("^\\d+_", "", colnames(x))
    colnames(x) <- gsub("Other_", "other", colnames(x))

    current_setting <- settings[[setting_hash]]
    x$year <- dfms[[rlang::hash(current_setting[1:3])]]
    rownames(x) <- NULL
    if (any(is.na(x$year))) {
        stop("NA in year!")
    }
    return(x)
}

future::plan(future::multisession, workers = getOption("tmmv.cores", 1))

aggregate_theta <- function(run) {
    multiverse <- readRDS(here(
        "intermediate",
        "jankin",
        "runs",
        run,
        "theta",
        "theta.RDS"
    ))

    multiverse <- furrr::future_map2(
        multiverse,
        names(multiverse),
        reformat_theta_matrix,
        .progress = TRUE
    )

    df <- bind_rows(multiverse, .id = "setting_hash")

    # this step is performed by Jankins as well
    # get the mean topic proportions across all documents
    # for a given year
    df_agg <- df |>
        group_by(setting_hash, year) |>
        summarise(across(starts_with("SDG"), \(x) mean(x, na.rm = TRUE))) |>
        pivot_longer(
            cols = where(is.double),
            names_to = "Topic",
            values_to = "Proportion"
        )

    stopifnot(length(unique(df_agg$Topic)) == 17)

    df_agg$Topic <- factor(
        df_agg$Topic,
        levels = names(tmmv.data[["jankin"]]$dict)
    )
    df_agg$run <- run
    df_agg$id <- paste0(df_agg$run, "_", df_agg$setting_hash)
    return(df_agg)
}

df_agg <- purrr::map(1:3, aggregate_theta) |> purrr::list_rbind()

settings_df <- bind_rows(
    map(settings, as.data.frame, simplify = FALSE),
    .id = "setting_hash"
)

jankin_k <- as.character(
    length(tmmv.data[["jankin"]]$dict) + tmmv.data[["jankin"]]$k
)

settings_df <- settings_df |>
    mutate(
        K = jankin_k[k_setting],
        model = if_else(
            alternative_model,
            tmmv.data[["jankin"]]$original_model,
            tmmv.data[["jankin"]]$alternative_model
        )
    )

jankin_settings <- tmmv.data[['jankin']]$anchor

stopifnot(rlang::hash(jankin_settings) %in% names(settings))

# Spaghetti Plots - OR: Jankin VS The Multiverse
# Caption:

# Mean topic proportions aggregated across all documents within each year,
# estimated from keyword-seeded topic models under 216 different settings (grey lines).
# Each panel shows one topic, with variation across settings.
# The blue line highlights estimates from the original configuration by Jankin et al.

year_breaks <- scale_x_continuous(breaks = c(1946, 1960, 1980, 2000, 2022))
theme_settings <- theme(
    plot.background = element_rect("white"),
    legend.position = "bottom"
)


p_spaghetti_full <- df_agg |>
    ggplot(aes(x = year, y = Proportion, group = id)) +
    geom_line(alpha = 0.02) +
    geom_line(
        data = df_agg[df_agg$setting_hash == rlang::hash(jankin_settings), ],
        color = tmmv.colors$lightblue,
        linewidth = 1,
    ) +
    theme_minimal() +
    theme_settings +
    year_breaks +
    facet_wrap(~Topic, ncol = 3, axes = "all_x")

ggsave(
    here("plots", "jankins_spaghetti_full.png"),
    plot = p_spaghetti_full,
    width = 3000,
    height = 4500,
    units = "px"
)

# Focus on same examples as Jankin et al
# Climate Change: SDG 13
# inclusive societies: SDG 16

p_spaghetti_sdg13_16 <- df_agg |>
    filter(Topic %in% c("SDG13", "SDG16")) |>
    ggplot(aes(
        x = year,
        y = Proportion,
        group = id,
    )) +
    geom_line(alpha = 0.03) +
    geom_line(
        data = df_agg[
            df_agg$Topic %in%
                c("SDG13", "SDG16") &
                df_agg$setting_hash == rlang::hash(jankin_settings),
        ],
        color = tmmv.colors$lightblue,
        linewidth = 1
    ) +
    theme_minimal() +
    theme_settings +
    year_breaks +
    facet_wrap(~Topic)

ggsave(
    here("plots", "jankins_spaghetti_sdg13_16.png"),
    plot = p_spaghetti_sdg13_16,
    width = 3000,
    height = 1500,
    units = "px"
)

# Create a mix of ribbon plot and a box plot
# Caption:
# Median yearly topic proportions across all settings (solid line),
# aggregated over documents within each year.
# Shaded ribbons show the interquartile range (first to third quartile) of proportions,
# while dots represent outlier settings beyond 1.5×IQR.
# This visualization provides a time-series analogue to a boxplot,
# illustrating how topic prevalence estimates vary across the multiverse of model configurations.
# The coloured variations show the impact of changing the K-setting and of the model family

df_box <- df_agg |>
    group_by(year, Topic) |>
    summarise(
        median = median(Proportion, na.rm = TRUE),
        first_quartile = quantile(Proportion, na.rm = TRUE)[2],
        third_quartile = quantile(Proportion, na.rm = TRUE)[4]
    )

df_box_outliers <- df_agg |>
    group_by(year, Topic) |>
    mutate(
        outlier = if_else(
            Proportion >
                quantile(Proportion, na.rm = TRUE)[4] +
                    1.5 * IQR(Proportion, na.rm = TRUE) |
                Proportion <
                    quantile(Proportion, na.rm = TRUE)[2] -
                        1.5 * IQR(Proportion, na.rm = TRUE),
            TRUE,
            FALSE
        )
    ) |>
    filter(outlier == TRUE) |>
    select(-outlier)

p_ribbon <- df_box |>
    ggplot(aes(x = year, y = median)) +
    geom_ribbon(
        aes(ymin = first_quartile, ymax = third_quartile),
        alpha = 0.2
    ) +
    geom_jitter(
        data = df_box_outliers,
        aes(x = year, y = Proportion),
        alpha = 0.1,
        stroke = 0
    ) +
    geom_line() +
    theme_minimal() +
    theme_settings +
    year_breaks +
    ylab("Proportion") +
    facet_wrap(~Topic, ncol = 3, axes = "all_x")

ggsave(
    here("plots", "jankins_ribbon.png"),
    plot = p_ribbon,
    width = 3500,
    height = 4000,
    units = "px"
)

# differentiate between model families

df_median_models <- df_agg |>
    left_join(settings_df, by = "setting_hash") |>
    group_by(model, year, Topic) |>
    summarise(
        median = median(Proportion, na.rm = TRUE),
        first_quartile = quantile(Proportion, na.rm = TRUE)[2],
        third_quartile = quantile(Proportion, na.rm = TRUE)[4]
    )

df_outliers_settings <- df_box_outliers |>
    left_join(settings_df, by = "setting_hash")


p_ribbon_models <- df_median_models |>
    ggplot(aes(x = year, y = median)) +
    geom_ribbon(
        aes(ymin = first_quartile, ymax = third_quartile, fill = model),
        alpha = 0.3
    ) +
    geom_jitter(
        data = df_outliers_settings,
        aes(x = year, y = Proportion, color = model),
        alpha = 0.1,
        stroke = 0
    ) +
    geom_line(aes(color = model)) +
    theme_minimal() +
    theme_settings +
    year_breaks +
    scale_color_manual(
        values = c(tmmv.colors$berrypurple, tmmv.colors$orange)
    ) +
    scale_fill_manual(
        values = c(tmmv.colors$berrypurple, tmmv.colors$orange)
    ) +
    facet_wrap(~Topic, ncol = 3, axes = "all_x")


ggsave(
    here("plots", "jankins_ribbon_models.png"),
    plot = p_ribbon_models,
    width = 3000,
    height = 4500,
    units = "px"
)


# differentiate between k-settings

df_median_k <- df_agg |>
    left_join(settings_df, by = "setting_hash") |>
    group_by(K, year, Topic) |>
    summarise(
        median = median(Proportion, na.rm = TRUE),
        first_quartile = quantile(Proportion, na.rm = TRUE)[2],
        third_quartile = quantile(Proportion, na.rm = TRUE)[4]
    )

p_ribbon_k <- df_median_k |>
    ggplot(aes(x = year, y = median)) +
    geom_ribbon(
        data = df_box,
        aes(ymin = first_quartile, ymax = third_quartile),
        alpha = 0.2
    ) +
    geom_jitter(
        data = df_outliers_settings,
        aes(x = year, y = Proportion, color = K),
        alpha = 0.1,
        stroke = 0
    ) +
    geom_line(aes(color = K)) +
    theme_minimal() +
    theme_settings +
    year_breaks +
    facet_wrap(~Topic, ncol = 3, axes = "all_x")


ggsave(
    here("plots", "jankins_ribbon_k.png"),
    plot = p_ribbon_k,
    width = 3000,
    height = 4500,
    units = "px"
)
