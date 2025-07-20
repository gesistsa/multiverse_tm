renv_available <- !identical(find.package("renv", quiet = TRUE, lib.loc = NULL), character(0))

if (Sys.getenv("INSIDEDOCKER") == "" && renv_available) {
    source("renv/activate.R")
}

source(here::here("lib.R"))
