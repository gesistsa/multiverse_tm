library(grateful)
library(here)
library(fs)

fs::dir_create(here("dev", "cite"), recurse = TRUE)

grateful::cite_packages(
    out.dir = here("dev", "cite"),
    out.format = "tex-fragment"
)
