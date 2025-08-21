library(ggplot2)

p <- diamonds |>
    ggplot() +
    aes(x = cut, fill = color) +
    geom_bar(position = "fill") +
    scale_fill_manual(values = tmmv.palette_safe) +
    theme_minimal()

# Dev dependency via https://github.com/clauswilke/colorblindr 
colorblindr::cvd_grid(p)
