## This script updates requirements.json, which is for updating README and Dockerfile

rpkgs <- sort(unique(renv::dependencies(quiet = TRUE)$Package))
system_requirements <- pak::pkg_sysreqs(setdiff(rpkgs, "RMeCab"))
rpkgs[
    rpkgs == "RMeCab"
] <- "IshidaMotohiro/RMeCab@2a11093f6a69ee11584aa0e2e8b32a59d1b9f092"

aptpkgs <- unique(c(
    "curl",
    "make",
    setdiff(
        as.character(system_requirements$packages$system_packages),
        c("pandoc-citeproc")
    ),
    "mecab",
    "libmecab-dev",
    "mecab-ipadic-utf8"
))

jsonlite::write_json(
    list(rpkgs = rpkgs, aptpkgs = aptpkgs),
    here::here("dev", "requirements.json")
)
