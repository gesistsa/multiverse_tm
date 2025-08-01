args <- tmmv.parse_args_train(slug = "czymara")

settings <- tmmv.get_settings(full = TRUE)

library(here)
library(keyATM)
library(quanteda)
library(purrr)
library(stm)
library(haven)
library(dplyr)
library(furrr)

## input <- haven::read_dta(here("rawdata/Corona-Survey_full.dta"))
## data_priv <- input |>
##     mutate(gender = case_match(DE03,
##                                1 ~ "male",
##                                2 ~ "female",
##                                .default = NA_character_)) |>
##     filter(!is.na(gender)) |> ##NOTE1
##     mutate(gender = factor(gender, levels = c("male", "female"))) |> #NOTE2
##     mutate(OF01_01 = stringr::str_trim(OF01_01)) |>
##     filter(OF01_01 != "" &
##            !stringr::str_detect(OF01_01, "^[[:space:]]+$")) ##NOTE3

## corpus_priv <- corpus(as.character(data_priv$OF01_01),
##                       docvars = data.frame(gender = data_priv$gender,
##                                            id = data_priv$CASE))

## the original setting in Czymara
anchor_setting <- list()
anchor_setting$token_normalization <- "stemming"
anchor_setting$stopword_removal <- TRUE
anchor_setting$trimming <- TRUE
anchor_setting$alternative_model <- FALSE
anchor_setting$k_setting <- 1
anchor_setting$iteration_setting <- 1

anchor_thetas = list()

anchor_mod <- readRDS(here(
    args$output_dir,
    paste0(rlang::hash(anchor_setting), ".RDS")
))

set.seed(anchor_mod$random_seed)

est <- estimateEffect(
    1:8 ~ gender,
    stmobj = anchor_mod$mod,
    metadata = anchor_mod$docvars
)


## Note that by default stm is 1 - 2
## https://github.com/bstewart/stm/blob/dbabf3405c660452bffc8bd1aaf72f7ea3867319/R/plottingutilfns.R#L168
res <- plot(
    est,
    covariate = "gender",
    model = anchor_mod$mod,
    method = "difference",
    cov.value1 = "female",
    cov.value2 = "male",
    omit.plot = TRUE
)

max_topic_index <- which.max(as.vector(res$means))
anchor_thetas[["max_gendered"]] <- anchor_mod$theta[, max_topic_index]

## as.character(corpus_priv[which.max(anchor_theta)])
## docvars(corpus_priv, "gender")[which.max(anchor_theta)]

czymara_topics <- readxl::read_xlsx(here("rawdata/czymara_topics.xlsx")) |>
    select(-`...1`)

topic_votes <- list()

for (topic in colnames(czymara_topics)) {
    token_idx <- which(anchor_mod$mod$vocab %in% czymara_topics[[topic]])
    topics_subset <- anchor_mod$mod$beta$logbeta[[1]][, token_idx]
    token_highest_topic <- apply(topics_subset, 2, order, decreasing = TRUE)[
        1,
    ]
    topic_votes[[topic]] <- token_highest_topic
}

# identify topic with lowest number of factor levels (~ most stable)
most_overlap_topic <- names(which.min(unlist(lapply(topic_votes, \(x) {
    length(levels(as.factor(x)))
}))))

# find the topic with highest overlap, stupid implementation
token_idx <- which(
    anchor_mod$mod$vocab %in% czymara_topics[[most_overlap_topic]]
)
topics_subset <- anchor_mod$mod$beta$logbeta[[1]][, token_idx]
token_highest_topic <- apply(topics_subset, 2, order, decreasing = TRUE)[1, ]

max_topic_index <- as.integer(names(which.max(table(as.factor(
    token_highest_topic
)))))
anchor_thetas[["highest_overlap"]] <- anchor_mod$theta[, max_topic_index]

# Social contacts as anchor

# find the topic with highest overlap, stupid implementation
token_idx <- which(
    anchor_mod$mod$vocab %in% czymara_topics[["Social.contacts"]]
)
topics_subset <- anchor_mod$mod$beta$logbeta[[1]][, token_idx]
token_highest_topic <- apply(topics_subset, 2, order, decreasing = TRUE)[1, ]

max_topic_index <- as.integer(names(which.max(table(as.factor(
    token_highest_topic
)))))
anchor_thetas[["social_contacts"]] <- anchor_mod$theta[, max_topic_index]


read_mod <- function(setting, anchor_theta) {
    current_mod <- readRDS(here(
        args$output_dir,
        paste0(rlang::hash(setting), ".RDS")
    ))
    k <- ncol(current_mod$theta)
    set.seed(current_mod$random_seed)
    if (setting$alternative_model) {
        strata_topic <- by_strata_DocTopic(
            current_mod$mod,
            by_var = "genderfemale",
            labels = c("male", "female")
        )
        theta1 <- strata_topic$theta[[1]]
        theta2 <- strata_topic$theta[[2]]

        theta_diff <- theta2[, seq_len(k)] - theta1[, seq_len(k)]

        theta_diff_quantile <- apply(theta_diff, 2, quantile, c(0.025, 0.975))
        theta_diff_mean <- apply(theta_diff, 2, mean)

        output <- list()

        for (anchor_variant in names(anchor_theta)) {
            anchor_index <- tmmv.find_anchor(
                anchor_theta[[anchor_variant]],
                current_mod$theta
            )
            tmp <- data.frame(
                Estimate = theta_diff_mean[anchor_index],
                Q2.5 = theta_diff_quantile[1, anchor_index],
                Q97.5 = theta_diff_quantile[2, anchor_index],
                anchor_variant = anchor_variant
            )
            rownames(tmp) <- NULL
            output[[anchor_variant]] <- tmp
        }
        output <- bind_rows(output)
    } else {
        est <- estimateEffect(
            ~gender,
            stmobj = current_mod$mod,
            metadata = current_mod$docvars
        )
        res <- plot(
            est,
            covariate = "gender",
            model = current_mod$mod,
            method = "difference",
            cov.value1 = "female",
            cov.value2 = "male",
            omit.plot = TRUE
        )

        output <- list()

        for (anchor_variant in names(anchor_theta)) {
            anchor_index <- tmmv.find_anchor(
                anchor_theta[[anchor_variant]],
                current_mod$theta
            )
            tmp <- data.frame(
                Estimate = as.vector(res$means)[anchor_index],
                Q2.5 = res$cis[[anchor_index]][1],
                Q97.5 = res$cis[[anchor_index]][2],
                anchor_variant = anchor_variant
            )
            colnames(tmp) <- c("Estimate", "Q2.5", "Q97.5", "anchor_variant")
            rownames(tmp) <- NULL
            output[[anchor_variant]] <- tmp
        }
        output <- bind_rows(output)
    }
    output <- output |> mutate(across(where(is.numeric), ~ round(.x, 6)))
    return(cbind(as.data.frame(setting), output))
}

if (args$debug) {
    plan(sequential)
} else {
    plan(multisession, workers = getOption("tmmv.cores", 1))
}

output_path <- here::here(
    "results",
    "aggregated",
    args$slug,
    paste0(args$current_run, ".csv")
)

res <- furrr::future_map(
    settings,
    read_mod,
    anchor_theta = anchor_thetas,
    .progress = TRUE,
    .options = furrr_options(seed = NULL)
) |>
    purrr::list_rbind() |>
    write.csv(output_path, row.names = FALSE)
