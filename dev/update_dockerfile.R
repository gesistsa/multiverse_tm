aptpkgs <- jsonlite::read_json(
    here::here("dev", "requirements.json"),
    simplifyVector = TRUE
)$aptpkgs

RUN_line <- paste0(
    "RUN apt update; apt install -y ",
    paste(aptpkgs, collapse = " ")
)

dockerfile_content <- readLines(here::here("Dockerfile"))

dockerfile_content[grepl("RUN apt update;", dockerfile_content)] <- RUN_line

writeLines(dockerfile_content, here::here("Dockerfile"))
