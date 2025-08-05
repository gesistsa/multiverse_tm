args <- tmmv.parse_args_train(slug = "jankin", .current_run = 1)
settings <- tmmv.get_settings(full = TRUE)

library(here)
library(keyATM)
library(quanteda)
library(SnowballC)
library(seededlda)
library(furrr)

get_theta <- function(setting, args) {
    current_mod <- readRDS(here(args$output_dir,
                                paste0(rlang::hash(setting), ".RDS")))
    current_mod$theta
}

output <- list()

for (setting in settings) {
    hash <- rlang::hash(setting)
    print(hash)
    current_mod <- readRDS(here(args$output_dir,
                                paste0(hash, ".RDS")))
    output[[hash]] <- current_mod$mod$theta
}
output_path <- here("intermediate", args$slug, "runs", args$current_run, "theta", "theta.RDS")
saveRDS(output, output_path)
