library(here)
library(future)
library(furrr)
library(purrr)

slug <- "tvinnereim"
run <- 1

settings <- tmmv.get_settings(full = TRUE)

args <- list()
args$output_dir <- here("intermediate", slug, "runs", run)
args$debug <- FALSE

## mod <- readRDS(tmmv.get_rds_filename(settings[[1]], args))

allcombis <- t(combn(seq_along(settings), 2))

## rowwise list
allcombis_list <- purrr::map(seq_len(nrow(allcombis)), \(x) {
    allcombis[x, , drop = TRUE]
})

calculate_cost <- function(combi, settings, args) {
    thetaa <- readRDS(tmmv.get_rds_filename(
        settings[[combi[1]]],
        args$output_dir
    ))$theta
    thetab <- readRDS(tmmv.get_rds_filename(
        settings[[combi[2]]],
        args$output_dir
    ))$theta
    tmmv.calculate_optimal_transport_cost(thetaa, thetab)
}

if (args$debug) {
    plan(sequential)
} else {
    plan(multisession, workers = getOption("tmmv.cores", 1))
}

print(Sys.time())
output <- furrr::future_map_dbl(
    allcombis_list,
    calculate_cost,
    settings = settings,
    args = args,
    .progress = TRUE
)
print(Sys.time())
