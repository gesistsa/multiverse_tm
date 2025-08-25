args <- tmmv.parse_args_train(slug = "chan")
settings <- tmmv.get_settings(full = TRUE, args = NULL)

dir.create(file.path(args$output_dir, "theta"), showWarnings = FALSE)
stopifnot(dir.exists(file.path(args$output_dir, "theta")))

theta <- list()

for (setting in settings) {
    current_hash <- rlang::hash(setting)
    mod_file <- file.path(args$output_dir, paste0(current_hash, ".RDS"))
    stopifnot(file.exists(mod_file))
    mod <- readRDS(mod_file)
    theta[[current_hash]] <- mod$mod$theta[, 1]
}

stopifnot(length(unique(purrr::map_int(theta, length))) == 1)

saveRDS(theta, file.path(args$output_dir, "theta", "theta.RDS"))
