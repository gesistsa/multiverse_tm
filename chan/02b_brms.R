args <- tmmv.parse_args_train(slug = "chan")

if (args$debug) {
    stop("No debug mode!")
}

args$output_dir <- fs::path(args$output_dir, "brms")

settings <- tmmv.get_settings(full = TRUE, args = args)

theta_path <- here::here(
    "intermediate",
    args$slug,
    "runs",
    args$current_run,
    "theta",
    "theta.RDS"
)

stopifnot(fs::file_exists(theta_path))

theta <- readRDS(theta_path)

tmmv.create_dir(args)

library(here)
library(purrr)
library(brms)

## if (args$debug) {
##     settings <- sample(settings, 2)
##     cat("DEBUG MODE: Only 2 randomly selected settings will be checked.\n")
##     cat("Rerun if you want more checks.\n")
## }

## original iter = 4000
train_brms <- function(setting, theta, iter = 4000, .fix_seed = NULL) {
    .fix_seed <- NULL
    current <- list()
    if (is.null(.fix_seed)) {
        current$random_seed <- sample(-65535:65535, 1)
    } else {
        current$random_seed <- .fix_seed
    }
    final_data <- readRDS(here("rawdata/final_data.RDS"))
    final_data$trending <- theta[[rlang::hash(setting)]]
    weaklyinformative_prior <- c(
        prior_string("normal(0, 1)", class = "b"),
        prior_string("normal(0, 1)", class = "Intercept")
    )
    set.seed(current$random_seed)
    tw_brms <- brm(
        rt_count ~
            OA *
                as.factor(G12) +
                Q1 * as.factor(G12) +
                trending * as.factor(G12) +
                offset(log(time)) +
                (1 | JI),
        data = final_data,
        family = zero_inflated_negbinomial(),
        cores = getOption("tmmv.cores", 1),
        control = list(adapt_delta = 0.80),
        iter = iter,
        prior = weaklyinformative_prior
    )

    output <- list()
    ## too big!
    ## output$brms <- tw_brms
    output$brms_fixef <- fixef(tw_brms)
    output$random_seed <- current$random_seed
    output$setting <- setting
    saveRDS(
        output,
        tmmv.get_rds_filename(setting, args$output_dir)
    )
}

purrr::walk(settings, train_brms, theta = theta, iter = 4000, .progress = TRUE)
