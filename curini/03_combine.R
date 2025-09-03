args <- tmmv.parse_args_train(slug = "curini")

if (args$debug) {
    stop("No debug mode!")
}

library(dplyr)
library(sandwich)
library(lmtest)
library(purrr)
library(here)

settings <- tmmv.get_settings(full = TRUE)

tmmv.create_dir(args, ontop = "theta")

conduct_regression <- function(setting, args) {
    mod <- readRDS(tmmv.get_rds_filename(setting, args$output_dir))

    theta <- tmmv.process_curini_theta_matrix(mod$mod$theta)
    ## Should save also the docvars in mod; but well...

    current_dfm <- readRDS(tmmv.get_rds_filename(
        setting[1:3],
        here("intermediate", args$slug)
    ))
    reg_data <- cbind(theta, current_dfm@docvars)

    ## from the original stata code
    ## reg multi100 c.lr##c.lr gov year i.code, r
    ## c. means continuous variable, i. means categorical

    ## Using quasibinomial or binomial won't affect the estimates; in most cases the SEs are the same
    ## Except in the case of overdispersion
    ## However, it's more correct to use quasibinomial for proportion outcomes; using binomial always produce
    ## a warning that the outcome variable is not integer.

    glmmod <- glm(
        multi100 ~ LR + I(LR^2) + Gov + Year + as.factor(Party),
        data = reg_data,
        family = quasibinomial("logit")
    )
    robustse <- coeftest(glmmod, vcov. = vcovHC(glmmod, type = "HC0"))

    output <- list()
    output$mod <- glmmod
    output$robustse <- robustse
    output$data <- reg_data
    output$setting <- setting
    return(output)
}

res <- purrr::map(settings, conduct_regression, args = args, .progress = TRUE)

main <- purrr::map_dbl(res, \(x) coef(x$mod)[2])
main_sq <- purrr::map_dbl(res, \(x) coef(x$mod)[3])

main_ci <- purrr::map(res, \(x) confint(x$robustse)[2, ])
main_sq_ci <- purrr::map(res, \(x) confint(x$robustse)[3, ])

output_path <- here::here(
    "results",
    "aggregated",
    args$slug,
    paste0(args$current_run, ".csv")
)

cbind(
    purrr::list_rbind(purrr::map(settings, as.data.frame)),
    data.frame(
        Estimate = main,
        Q2.5 = purrr::map_dbl(main_ci, 1),
        Q97.5 = purrr::map_dbl(main_ci, 2)
    ) |>
        round(6),
    data.frame(
        Estimate.sq = main_sq,
        Q2.5 = purrr::map_dbl(main_sq_ci, 1),
        Q97.5 = purrr::map_dbl(main_sq_ci, 2)
    ) |>
        round(6)
) |>
    write.csv(output_path, row.names = FALSE)

theta <- purrr::map(res, \(x) x$data$multi100)
names(theta) <- purrr::map_chr(settings, \(x) rlang::hash(x))
saveRDS(theta, fs::path(args$output_dir, "theta", "theta.RDS"))

generate_conditional_effect <- function(res, hash) {
    .f = function(x, mod, data) {
        new_data <- data
        new_data$LR <- x
        round(mean(predict(mod, new_data, type = "response")), 6)
    }
    data.frame(
        hash = hash,
        LR = seq(0, 10, 0.5),
        pred_multi100 = purrr::map_dbl(
            seq(0, 10, 0.5),
            .f,
            mod = res$mod,
            data = res$data
        )
    )
}

output_path <- here::here(
    "results",
    "aggregated",
    args$slug,
    paste0("condit_", args$current_run, ".csv")
)

condit_effect <- purrr::map2(
    res,
    purrr::map_chr(settings, \(x) rlang::hash(x)),
    generate_conditional_effect
) |>
    purrr::list_rbind() |>
    write.csv(output_path, row.names = FALSE)
