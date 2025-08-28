library(psych)
library(here)
read_theta <- function(slug) {
    
}

slug <- "takano"
run <- 1

read_thetas <- function(slug) {
    .f <- function(run, slug) {
        path <- here("intermediate", slug, "runs", run, "theta/theta.RDS")
        if (fs::file_exists(path)) {
            return(readRDS(path))
        }
        NULL
    }
    purrr::map(c(1,2,3), .f = .f, slug = slug)
}

thetas <- read_thetas("czymara")

hashes <- names(thetas[[1]])

thetas |> purrr::map(hashes[13]) |> tmmv.calculate_icc()

    purrr::map(as.data.frame) |> purrr::quietly(purrr::list_cbind)() |> purrr::chuck("result") |> psych::ICC(lmer = FALSE)

thetas |> purrr::map(hashes[13]) |> unique() |> length()

|> purrr::map(as.data.frame) |> purrr::quietly(purrr::list_cbind)() |> purrr::chuck("result") |> 

|> tmmv.calculate_icc()


all_iccs <- hashes |> purrr::map(\(x) thetas |> purrr::map(x) |> tmmv.calculate_icc(), .progress = TRUE)

hashes[38] |> purrr::map(\(x) thetas |> purrr::map(x) |> tmmv.calculate_icc(), .progress = TRUE)

x2 <- purrr::map(thetas, hashes[38]) |> purrr::map(as.data.frame) |> purrr::quietly(purrr::list_cbind)() |> purrr::chuck("result")

psych::ICC(x2, lmer = FALSE)
