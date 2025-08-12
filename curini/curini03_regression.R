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

get_theta_by_topic_name <- function(topic_name, mod) {
    topic_index <- which(stringr::str_detect(colnames(mod$mod$theta), topic_name))
    if (identical(topic_index, integer(0))) {
        return(rep(0, nrow(mod$mod$theta)))
    }
    return(mod$mod$theta[,topic_index, drop = TRUE])
}

conduct_regression <- function(setting, args) {
    mod <- readRDS(file.path(args$output_dir, paste0(rlang::hash(setting), ".RDS")))

    theta <- rep(0, nrow(mod$mod$theta) * 3) |>
        matrix(ncol = 3) |>
        as.data.frame()

    colnames(theta) <- c("multilateralism", "humanitarian_dimension", "war")


    for (cnames in colnames(theta)) { 
        theta[, cnames] <- get_theta_by_topic_name(cnames, mod)
    }

    ## Should save also the docvars in mod; but well...

    current_dfm <- readRDS(here("intermediate", args$slug,
                                paste0(rlang::hash(setting[1:3]), ".RDS")))

    reg_data <- cbind(theta, current_dfm@docvars)

    ## from the original stata code

    # gen multi100 = multilateralism/(multilateralism+humanitarian_dimensio+war)
    # gen humi100 = humanitarian_dimensio/(multilateralism+humanitarian_dimensio+war)
    # gen war100 = war/(multilateralism+humanitarian_dimensio+war)

    reg_data <- reg_data |> mutate(t3 = multilateralism + humanitarian_dimension + war,
                                   multi100 = multilateralism / t3,
                                   humi100 = humanitarian_dimension / t3,
                                   war100 = war / t3) |>
        select(-t3)

    ## from the original stata code
    ## reg multi100 c.lr##c.lr gov year i.code, r
    ## c. means continuous variable, i. means categorical

    ## Using quasibinomial or binomial won't affect the estimates; in most cases the SEs are the same
    ## Except in the case of overdispersion
    ## However, it's more correct to use quasibinomial for proportion outcomes; using binomial always produce
    ## a warning that the outcome variable is not integer.

    glmmod <- glm(multi100~LR+I(LR^2)+Gov+Year+as.factor(Party), data = reg_data, family = quasibinomial("logit"))
    robustse <- coeftest(glmmod, vcov.=vcovHC(glmmod, type="HC0"))

    output <- list()
    output$mod <- glmmod
    output$robustse <- robustse
    output$data <- reg_data
    output$setting <- setting
    return(output)
}

res <- purrr::map(settings,
                  conduct_regression,
                  args = args,
                  .progress = TRUE)

main <- purrr::map_dbl(res, \(x) coef(x$mod)[2]) 
main_sq <- purrr::map_dbl(res, \(x) coef(x$mod)[3])

main_ci <- purrr::map(res, \(x) confint(x$robustse)[2,])
main_sq_ci <- purrr::map(res, \(x) confint(x$robustse)[3,])

output_path <- here::here("results", "aggregated", args$slug, paste0(args$current_run, ".csv"))

cbind(purrr::list_rbind(purrr::map(settings, as.data.frame)),
      data.frame(Estimate = main, Q2.5 = purrr::map_dbl(main_ci, 1), Q97.5 = purrr::map_dbl(main_ci, 2)) |> round(6),
      data.frame(Estimate.sq = main_sq, Q2.5 = purrr::map_dbl(main_sq_ci, 1), Q97.5 = purrr::map_dbl(main_sq_ci, 2)) |> round(6)) |>
    write.csv(output_path, row.names = FALSE)


hashes <- purrr::map_chr(settings, \(x) rlang::hash(x))

generate_conditional_effect <- function(res, hash) {
    .f = function(x, mod, data) {
        new_data <- data
        new_data$LR <- x
        mean(predict(mod, new_data, type = "response"))
    }
    data.frame(hash = hash, LR = seq(0, 10, 0.5),
               pred_multi100 = purrr::map_dbl(seq(0, 10, 0.5),
                                              .f,
                                              mod = res$mod,
                                              data = res$data))
}

output_path <- here::here("results", "aggregated", args$slug, paste0("condit_", args$current_run, ".csv"))

condit_effect <- purrr::map2(res,
                             hashes,
                             generate_conditional_effect) |>
    purrr::list_rbind() |>
    write.csv(output_path, row.names = FALSE)
    

