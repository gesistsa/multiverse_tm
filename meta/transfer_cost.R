library(here)
library(future)
library(furrr)
library(purrr)

read_theta_matrix <- function(args, settings) {
    if (args$slug == "jankin") {
        return(readRDS(here(
            "intermediate",
            args$slug,
            "runs",
            args$run,
            "theta",
            "theta.RDS"
        )))
    }
    .f <- function(x, args) {
        input <- readRDS(tmmv.get_rds_filename(
            x,
            args$output_dir
        ))
        if (args$slug == "curini") {
            return(tmmv.process_curini_theta_matrix(
                input$mod$theta,
                df = FALSE
            ))
        }
        if (args$slug != "chan") {
            return(input$theta)
        } else {
            return(input$mod$theta)
        }
    }

    all_thetas <- purrr::map(settings, .f, args = args)
    all_hashes <- purrr::map_chr(settings, rlang::hash)
    names(all_thetas) <- all_hashes
    return(all_thetas)
}

calculate_cost <- function(args) {
    .f <- function(combi, all_thetas, random_seed) {
        set.seed(random_seed)
        all_hashes <- names(all_thetas)
        thetaa <- all_thetas[[all_hashes[combi[1]]]]
        thetab <- all_thetas[[all_hashes[combi[2]]]]
        tmmv.calculate_optimal_transport_cost(thetaa, thetab)
    }

    settings <- tmmv.get_settings(full = TRUE)

    if (args$slug == "takano") {
        settings <- settings |>
            purrr::keep(\(x) x$token_normalization != "stemming")
    }

    if (args$debug) {
        settings <- sample(settings, 5)
        cat("DEBUG MODE: Only 5 randomly selected settings will be checked.\n")
        cat("Rerun if you want more checks.\n")
    }
    args$output_dir <- here("intermediate", args$slug, "runs", args$run)

    allcombis <- t(combn(seq_along(settings), 2))

    ## rowwise list
    allcombis_list <- purrr::map(seq_len(nrow(allcombis)), \(x) {
        allcombis[x, , drop = TRUE]
    })

    all_thetas <- read_theta_matrix(args, settings)

    random_seed <- sample(-65535:65535, 1)
    ini_time <- Sys.time()
    cost <- furrr::future_map_dbl(
        .x = allcombis_list,
        .f = .f,
        all_thetas = all_thetas,
        random_seed = random_seed,
        .progress = TRUE,
        .options = furrr_options(seed = NULL)
    )
    cat("Elapsed time:\n")
    print(Sys.time() - ini_time)
    output <- list()
    output$result <- data.frame(
        i = purrr::map_int(allcombis_list, 1),
        j = purrr::map_int(allcombis_list, 2),
        cost = cost
    )
    output$seed <- random_seed
    output$settings <- settings
    return(output)
}

## mod <- readRDS(tmmv.get_rds_filename(settings[[1]], args))

args <- list()
args$debug <- FALSE
args$run <- 1

if (args$debug) {
    plan(sequential)
} else {
    plan(multisession, workers = getOption("tmmv.cores", 1))
}

for (slug in c("curini", "czymara", "takano", "tvinnereim")) {
    args$slug <- slug
    if (!args$debug) {
        output_dir <- here::here("results", args$slug, "costs")
    } else {
        output_dir <- here::here("debug_results", args$slug, "costs")
    }
    fs::dir_create(output_dir, recurse = TRUE)
    calculate_cost(args = args) |>
        saveRDS(fs::path(output_dir, paste0(args$run, ".RDS")))
}

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
