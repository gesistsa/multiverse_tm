args <- tmmv.parse_args_train(slug = "chan")

if (args$debug) {
    stop("No debug mode!")
}

args$output_dir <- fs::path(args$output_dir, "brms")

settings <- tmmv.get_settings(full = TRUE)

read_brms <- function(setting, args = args) {
    brms_obj <- readRDS(tmmv.get_rds_filename(setting, args$output_dir))
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

purrr::map(settings, read_brms, args = args) |>
    purrr::list_rbind() |>
    write.csv(output_path, row.names = FALSE)
