library(stm)

args <- tmmv.parse_args_train(slug = "tvinnereim", .current_run = 1)

analytical_paths <- list(
    token_normalization = c("none", "lemmatization", "stemming"),
    stopword_removal = c(TRUE, FALSE),
    trimming = c(TRUE, FALSE),
    alternative_model = c(TRUE, FALSE),
    k_setting = c(1, 2, 3), #K original, alt1, alt2
    iteration_setting = c(1, 2, 3) #iter original, alt1, alt2
)

settings_df <- expand.grid(analytical_paths, stringsAsFactors = FALSE)

settings <- settings_df |> purrr::transpose()


.read <- function(setting, args) {
    readRDS(tmmv.get_rds_filename(
        setting,
        here::here(args$output_dir)
    ))
}

models <- purrr::map(settings, .read, args = args)
names(models) <- purrr::map_chr(settings, rlang::hash)

anchor_setting <- list(
    token_normalization = "stemming",
    stopword_removal = TRUE,
    trimming = TRUE,
    alternative_model = FALSE,
    k_setting = 1,
    iteration_setting = 1
)

anchor_mod <- models[[rlang::hash(anchor_setting)]]

.gen_anchor <- function(anchor_mod, edu3 = TRUE) {
    if (edu3) {
        est <- stm::estimateEffect(
            ~ concern + edu3 + gender + age,
            stmobj = anchor_mod$mod,
            metadata = anchor_mod$docvars
        )
    } else {
        anchor_mod$docvars$univdummy <- as.numeric(anchor_mod$docvars$edu3 == 3)
        est <- stm::estimateEffect(
            ~ concern + univdummy + gender + age,
            stmobj = anchor_mod$mod,
            metadata = anchor_mod$docvars
        )
    }
    max_topic_index <- which.max(
        purrr::map_dbl(est$parameters, \(x) {
            mean(purrr::map_dbl(x, \(y) y$est["age"]))
        })
    )

    return(anchor_mod$theta[, max_topic_index])
}


## the anchors are the same
stopifnot(identical(
    .gen_anchor(anchor_mod, edu3 = TRUE),
    .gen_anchor(anchor_mod, edu3 = FALSE)
))
