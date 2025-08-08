library(here)
library(ggplot2)
library(dplyr)
library(tidyr)
library(furrr)

tmmv.colors <- list(
    lightblue = "#1E8CC8",
    berrypurple = "#642878",
    orange = "#F08741"
)

# Restore meta data
settings <- tmmv.get_settings()
names(settings) <- unlist(lapply(settings, rlang::hash))

dfm_filenames <- unique(unlist(lapply(settings, \(x) rlang::hash(x[1:3]))))

dfms <- sapply(
    dfm_filenames,
    \(x) {
        dfm_filename <- paste0(x, ".RDS")
        dfm <- readRDS(here("intermediate", "jankin", dfm_filename))
        return(rownames(dfm))
    },
    simplify = FALSE
)


multiverse <- readRDS(here(
    "intermediate",
    "jankin",
    "runs",
    "1",
    "theta",
    "theta.RDS"
))

reformat_theta_matrix <- function(x, setting_hash) {
    x <- as.data.frame(x)
    colnames(x) <- gsub("^\\d+_", "", colnames(x))
    colnames(x) <- gsub("Other_", "other", colnames(x))

    current_setting <- settings[[setting_hash]]
    x$doc_id <- dfms[[rlang::hash(current_setting[1:3])]]
    rownames(x) <- NULL
    if (any(is.na(x$doc_id))) {
        stop("NA in doc_id!")
    }
    return(x)
}

future::plan(future::multisession, workers = 8)

multiverse <- furrr::future_map2(
    multiverse,
    names(multiverse),
    reformat_theta_matrix,
    .progress = TRUE
)

df <- bind_rows(multiverse, .id = "setting_hash")

df$year <- as.integer(stringr::str_split_fixed(df$doc_id, "_", 2)[, 2])

stopifnot(!any(is.na(df$year)))


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
    levels = c(
        "SDG1",
        "SDG2",
        "SDG3",
        "SDG4",
        "SDG5",
        "SDG6",
        "SDG7",
        "SDG8",
        "SDG9",
        "SDG10",
        "SDG12",
        "SDG11",
        "SDG13",
        "SDG14",
        "SDG15",
        "SDG16",
        "SDG17"
    )
)


settings_df <- bind_rows(
    sapply(settings, as.data.frame, simplify = FALSE),
    .id = "setting_hash"
)

settings_df <- settings_df |>
    mutate(
        K = case_match(k_setting, 1 ~ "18", 2 ~ "20", 3 ~ "22"),
        model = if_else(alternative_model, "KeyATM", "SeededLDA")
    )

jankin_settings <- list(
    token_normalization = "none",
    stopword_removal = TRUE,
    trimming = FALSE,
    alternative_model = FALSE,
    k_setting = 1,
    iteration_setting = 1
)

stopifnot(rlang::hash(jankin_settings) %in% names(settings))

# Spaghetti Plots - OR: Jankin VS The Multiverse

p_spaghetti_full <- df_agg |>
    ggplot(aes(x = year, y = Proportion, group = setting_hash)) +
    geom_line(alpha = 0.1) +
    geom_line(
        data = df_agg[df_agg$setting_hash == rlang::hash(jankin_settings), ],
        color = tmmv.colors$lightblue,
        linewidth = 2,
    ) +
    theme_minimal() +
    theme(plot.background = element_rect("white")) +
    facet_wrap(~Topic, ncol = 3, axis = "all_y")

ggsave(
    "plots/jankins_spaghetti_full.png",
    plot = p_spaghetti_full,
    width = 3000,
    height = 4500,
    units = "px"
)

# Climate Change: SDG 13
# In contrast, there is little engagement with climate change (SDG-13)
# until the 1990s, before rising sharply in the 2000s to become the topic with one of the highest distributions in countries’ UNGD statements.
# peace and inclusive societies (SDG-16)

p_spaghetti_sdg13_16 <- df_agg |>
    filter(Topic %in% c("SDG13", "SDG16")) |>
    ggplot(aes(
        x = year,
        y = Proportion,
        group = setting_hash,
    )) +
    geom_line(alpha = 0.2) +
    geom_line(
        data = df_agg[
            df_agg$Topic %in%
                c("SDG13", "SDG16") &
                df_agg$setting_hash == rlang::hash(jankin_settings),
        ],
        color = tmmv.colors$lightblue,
        linewidth = 2
    ) +
    theme_minimal() +
    theme(plot.background = element_rect("white")) +
    facet_wrap(~Topic)

ggsave(
    "plots/jankins_spaghetti_sdg13_16.png",
    plot = p_spaghetti_sdg13_16,
    width = 3000,
    height = 1500,
    units = "px"
)

# Create a mix of ribbon plot and a box plot

df_box <- df_agg |>
    group_by(year, Topic) |>
    summarise(
        median = median(Proportion, na.rm = TRUE),
        first_quartile = quantile(Proportion, na.rm = TRUE)[2],
        third_quartile = quantile(Proportion, na.rm = TRUE)[4]
    )

df_box_outliers <- df_agg |>
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

p_ribbon_boxplot <- df_box |>
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
    theme(plot.background = element_rect("white")) +
    facet_wrap(~Topic, ncol = 3)


ggsave(
    "plots/jankins_boxplots_full.png",
    plot = p_ribbon_boxplot,
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
    theme(plot.background = element_rect("white"), legend.position = "bottom") +
    scale_color_manual(
        values = c(tmmv.colors$berrypurple, tmmv.colors$orange)
    ) +
    scale_fill_manual(
        values = c(tmmv.colors$berrypurple, tmmv.colors$orange)
    ) +
    facet_wrap(~Topic, ncol = 3)


ggsave(
    "plots/jankins_ribbon_models.png",
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
    theme(plot.background = element_rect("white"), legend.position = "bottom") +
    facet_wrap(~Topic, ncol = 3)


ggsave(
    "plots/jankins_ribbon_k.png",
    plot = p_ribbon_k,
    width = 3000,
    height = 4500,
    units = "px"
)
