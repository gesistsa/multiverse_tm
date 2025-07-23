renv_available <- !identical(find.package("renv", quiet = TRUE, lib.loc = NULL), character(0))

if (Sys.getenv("INSIDEDOCKER") == "" && renv_available) {
    source("renv/activate.R")
}

source(here::here("lib.R"))

## Options for this project

## # of cores for brms and co.
options(tmmv.cores = 6)
