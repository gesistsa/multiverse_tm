library(here)
library(future)
library(furrr)
library(purrr)

slug <- "tvinnereim"
run <- 1

settings <- tmmv.get_settings(full = TRUE)

args$output_dir <- here("intermediate", slug, "runs", run)
args$debug <- FALSE

## mod <- readRDS(tmmv.get_rds_filename(settings[[1]], args))

allcombis <- t(combn(seq_along(settings), 2))

## rowwise list
allcombis_list <- purrr::map(seq_len(nrow(allcombis)), \(x) {
    allcombis[x, , drop = TRUE]
})

all_thetas <- purrr::map(settings, \(x) {
    readRDS(tmmv.get_rds_filename(
        x,
        args$output_dir
    ))$theta
})

all_hashes <- purrr::map_chr(settings, rlang::hash)
names(all_thetas) <- all_hashes


calculate_cost <- function(combi, all_thetas, all_hashes) {
    thetaa <- all_thetas[[all_hashes[combi[1]]]]
    thetab <- all_thetas[[all_hashes[combi[2]]]]
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
    all_thetas = all_thetas,
    all_hashes = all_hashes,
    .progress = TRUE
)
print(Sys.time())

saveRDS(output, "dev/tvinnereim.RDS")

args$output_dir <- here("intermediate", "czymara", "runs", run)

print(Sys.time())
output <- furrr::future_map_dbl(
    allcombis_list,
    calculate_cost,
    settings = settings,
    args = args,
    .progress = TRUE
)
print(Sys.time())

saveRDS(output, "dev/czymara.RDS")
hist(readRDS("dev/tvinnereim.RDS"))

mean(readRDS("dev/czymara.RDS"))
mean(readRDS("dev/tvinnereim.RDS"))


node_i <- purrr::map_int(allcombis_list, 1)
node_j <- purrr::map_int(allcombis_list, 2)

weight <- readRDS("dev/tvinnereim.RDS")

library(igraph)
library(dplyr)

g <- graph_from_data_frame(data.frame(node_i, node_j, weight), directed = FALSE)

eccentricity(g)

## the fact that the graph is fully connected, make these two the same: two nodes must be connected by just one edge
node_n <- 2
data.frame(node_i, node_j, weight) |>
    dplyr::filter(node_i == node_n | node_j == node_n) |>
    select(weight) |>
    max()
eccentricity(g)[node_n]
