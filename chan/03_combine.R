args <- tmmv.parse_args_train(slug = "chan")

if (args$debug) {
    stop("No debug mode!")
}

args$output_dir <- file.path(args$output_dir, "brms")

settings <- tmmv.get_settings(full = TRUE)

read_brms <- function(setting) {
    brms_obj <- readRDS(file.path(
        args$output_dir,
        paste0(rlang::hash(setting), ".RDS")
    ))
    output <- cbind(
        as.data.frame(setting),
        as.data.frame(t(brms_obj$brms_fixef["trending", ]))
    )
    return(output)
}

output_path <- here::here(
    "results",
    "aggregated",
    args$slug,
    paste0(args$current_run, ".csv")
)

purrr::map(settings, read_brms) |>
    purrr::list_rbind() |>
    write.csv(output_path, row.names = FALSE)
