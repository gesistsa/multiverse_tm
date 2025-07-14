library(renv)
renv::init(bare = TRUE)

install.packages("pak")

packages <- c(
    "here",
    "readtext",
    "quanteda",
    "stringr",
    "purrr",
    "testthat",
    "keyATM",
    "SnowballC",
    "textstem",
    "seededlda"
)

pak::pkg_install(packages)

renv::snapshot()