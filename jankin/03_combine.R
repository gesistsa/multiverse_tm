args <- tmmv.parse_args_train(slug = "jankin")
settings <- tmmv.get_settings(full = TRUE)

library(here)
## library(keyATM)
## library(quanteda)
## library(SnowballC)
## library(seededlda)
## library(furrr)

output <- list()

for (setting in settings) {
    hash <- rlang::hash(setting)
    current_mod <- readRDS(tmmv.get_rds_filename(setting, args$output_dir))
    output[[hash]] <- current_mod$mod$theta
}

tmmv.create_dir(args, ontop = "theta")

output_path <- here(
    "intermediate",
    args$slug,
    "runs",
    args$current_run,
    "theta",
    "theta.RDS"
)

saveRDS(output, output_path)
