#library(osfr)

args <- commandArgs(trailingOnly=TRUE)

if (length(args) < 2) {
    stop("You must provide the osf handle and the destination directory, e.g. Rscript osf_download.R 3hazf rawdata")
}

osf_handle <- args[1]
output_dir <- args[2]

outcome <- osfr::osf_retrieve_file(osf_handle) |> osfr::osf_download(path = here::here(output_dir), conflicts = "skip", progress = TRUE)

stopifnot(file.exists(outcome$local_path[1]))
