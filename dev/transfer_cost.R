library(here)
library(future)
library(furrr)
library(purrr)

args <- list()
args$debug <- TRUE
args$slug <- "tvinnereim"
args$run <- 1

calculate_cost <- function(args) {
    .f <- function(combi, all_thetas, all_hashes, random_seed) {
        set.seed(random_seed)
        thetaa <- all_thetas[[all_hashes[combi[1]]]]
        thetab <- all_thetas[[all_hashes[combi[2]]]]
        tmmv.calculate_optimal_transport_cost(thetaa, thetab)
    }

    ## TODO: Takano,
    settings <- tmmv.get_settings(full = TRUE)
    if (args$debug) {
        settings <- sample(settings, 3)
        cat("DEBUG MODE: Only 3 randomly selected settings will be checked.\n")
        cat("Rerun if you want more checks.\n")
    }
    args$output_dir <- here("intermediate", args$slug, "runs", args$run)

    allcombis <- t(combn(seq_along(settings), 2))

    ## rowwise list
    allcombis_list <- purrr::map(seq_len(nrow(allcombis)), \(x) {
        allcombis[x, , drop = TRUE]
    })
    ##TODO: curini, chan, jakin
    all_thetas <- purrr::map(settings, \(x) {
        readRDS(tmmv.get_rds_filename(
            x,
            args$output_dir
        ))$theta
    })
    all_hashes <- purrr::map_chr(settings, rlang::hash)
    names(all_thetas) <- all_hashes
    random_seed <- sample(-65535:65535, 1)
    ini_time <- Sys.time()
    cost <- furrr::future_map_dbl(
        .x = allcombis_list,
        .f = .f,
        all_thetas = all_thetas,
        all_hashes = all_hashes,
        random_seed = random_seed,
        .progress = TRUE,
        .options = furrr_options(seed = NULL)
    )
    cat("Elapsed time:\n")
    print(Sys.time() - ini_time)
    if (!args$debug) {
        output_dir <- here::here("results", args$slug, "costs")
    } else {
        output_dir <- here::here("debug_results", args$slug, "costs")
    }
    fs::dir_create(output_dir, recurse = TRUE)
    output <- list()
    node_i <- purrr::map_int(allcombis_list, 1)
    node_j <- purrr::map_int(allcombis_list, 2)
    output$result <- data.frame(i = node_i, j = node_j, cost = cost)
    output$seed <- random_seed
    output$settings <- settings
    saveRDS(output, fs::path(output_dir, paste0(args$run, ".RDS")))
    invisible(NULL)
}

## mod <- readRDS(tmmv.get_rds_filename(settings[[1]], args))

if (args$debug) {
    plan(sequential)
} else {
    plan(multisession, workers = getOption("tmmv.cores", 1))
}

calculate_cost(args)

## saveRDS(output, "dev/tvinnereim.RDS")

## args$output_dir <- here("intermediate", "czymara", "runs", run)

## print(Sys.time())
## output <- furrr::future_map_dbl(
##     allcombis_list,
##     calculate_cost,
##     settings = settings,
##     args = args,
##     .progress = TRUE
## )
## print(Sys.time())

## ## saveRDS(output, "dev/czymara.RDS")
## ## hist(readRDS("dev/tvinnereim.RDS"))

## ## mean(readRDS("dev/czymara.RDS"))
## ## mean(readRDS("dev/tvinnereim.RDS"))

## ## node_i <- purrr::map_int(allcombis_list, 1)
## ## node_j <- purrr::map_int(allcombis_list, 2)

## ## weight <- readRDS("dev/tvinnereim.RDS")

## ## library(igraph)
## ## library(dplyr)

## ## g <- graph_from_data_frame(data.frame(node_i, node_j, weight), directed = FALSE)

## ## eccentricity(g)

## ## ## the fact that the graph is fully connected, make these two the same: two nodes must be connected by just one edge
## ## node_n <- 2
## ## data.frame(node_i, node_j, weight) |>
## ##     dplyr::filter(node_i == node_n | node_j == node_n) |>
## ##     select(weight) |>
## ##     max()
## ## eccentricity(g)[node_n]
