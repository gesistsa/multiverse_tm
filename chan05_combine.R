args <- tmmv.parse_args_train(slug = "chan", debug = TRUE)

if (args$debug) {
    stop("No debug mode!")
}

args$output_dir <- file.path(args$output_dir, "brms")

##args$output_dir <- here::here("intermediate", "chan", "runs", "1", "brms")

settings <- tmmv.get_settings(full = TRUE, args = args)


read_brms <- function(setting) {
    brms_obj <- readRDS(file.path(args$output_dir,
                                  paste0(rlang::hash(setting), ".RDS")))
    output <- cbind(as.data.frame(setting),
                    as.data.frame(t(brms_obj$brms_fixef["trending", ])))
    return(output)
}

overall <- purrr::map(settings, read_brms) |>
    purrr::list_rbind()

library(ggplot2)

overall |> arrange(Estimate) |>
    mutate(alternative_model =
               if_else(alternative_model, "Seeded", "keyATM")) |>
    mutate(k_setting = case_match(k_setting,
                                  1 ~ "K = 39",
                                  2 ~ "K = 35",
                                  3 ~ "K = 43")) |> 
    mutate(rank = row_number()) |>
    ggplot(aes(x = rank, y = Estimate)) +
    geom_point() +
    geom_linerange(aes(ymin = Q2.5, ymax = Q97.5)) +
    facet_grid(rows = vars(alternative_model),
               cols = vars(k_setting)) +
    ylim(-1, 6)
