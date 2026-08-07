args <- tmmv.parse_args_read(slug = "jankin")
settings <- tmmv.get_settings(full = FALSE, args = args)

library(here)

stopifnot(dir.exists(here("rawdata/jankin/TXT")))

library(quanteda)
library(stringr)
library(purrr)

## Modified from the original RMD file

ungd_files <- tmmv.read_text_base(
    here("rawdata/jankin/TXT/"),
    dvsep = "_",
    docvarnames = c("Country", "Session", "Year")
)

ungd_files$doc_id <- str_replace(ungd_files$doc_id, ".txt", "") |>
    str_replace("_\\d{2}", "")

rownames(ungd_files) <- NULL

saveRDS(ungd_files, here("rawdata/ungd_files.RDS"))
