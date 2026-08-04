renv_available <- !identical(find.package("renv", quiet = TRUE, lib.loc = NULL), character(0))

if (Sys.getenv("INSIDEDOCKER") == "" && !renv_available) {
    warning("It appears that you have not initialized renv yet. Please install 'renv', run 'renv::activate()' and then 'renv::restore().")
}

if (Sys.getenv("INSIDEDOCKER") == "" && renv_available) {
    source("renv/activate.R")
}

here_available <- !identical(find.package("here", quiet = TRUE, lib.loc = NULL), character(0))

if (!here_available) {
    warning("Your computational environment might not be configurated correctly. Please retry or check!")
} else {
    source(here::here("lib/lib.R"))
}

## Options for this project

## see ?renv::config
options(renv.config.pak.enabled = FALSE)

## # of cores for brms and co.
options(tmmv.cores = 6)

## # of parallel sessions for running jankin02_train.R
options(tmmv.jankin.workers = 4)
