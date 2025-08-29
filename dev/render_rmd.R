## This looks stupid. But we want to make renv detect quarto
## for the dev profile
quarto::quarto_render("readme.rmd", output_file = "readme.md")
