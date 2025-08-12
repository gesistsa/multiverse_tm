input_path <- here::here("rawdata/jankin/TXT/")
txt_files <- sample(list.files(input_path, recursive = TRUE), 100)


txt_content <- vapply(txt_files,
                      function(x) paste(suppressWarnings(readLines(file.path(input_path, x))),
                                        collapse = "\n"),
                      character(1))

txt_broken <- strsplit(txt_content, " ")

txt_shuffled <- lapply(txt_broken, function(x) paste0(sample(x), collapse = " "))

dir.create(here::here("dev/TXT"), recursive = TRUE)

for (i in seq_along(txt_shuffled)) {
    dir.create(here::here("dev/TXT", dirname(txt_files[i])), showWarnings = FALSE)
    writeLines(txt_shuffled[[i]], here::here("dev/TXT", txt_files[i]))
}
