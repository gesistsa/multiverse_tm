## This looks stupid. But we want to make renv detect quarto
## for the dev profile
quarto::quarto_render(
    input = "readme.rmd",
    output_file = "readme.md",
    output_format = "gfm"
)
