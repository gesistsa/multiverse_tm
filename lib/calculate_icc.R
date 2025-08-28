# Modified from William Revelle (2025). psych: Procedures for Psychological, Psychometric, and Personality Research. Northwestern University, Evanston, Illinois. R package version 2.5.6, https://CRAN.R-project.org/package=psych.
# Original license: GPL >= 2
tmmv.calculate_icc <- function(x) {
    ## please note that x can be named list
    if (length(unique(x)) == 1) {
        ## all the same, usually the case for STM with spectral initialization
        return(1)
    }
    x <- purrr::map(x, as.data.frame) |>
        purrr::quietly(purrr::list_cbind)() |>
        purrr::chuck("result")
    ## most of the code below was copied from psych::ICC version 2.5.6
    n.obs <- nrow(x)
    nj <- ncol(x)
    x.s <- stack(x)
    x.df <- data.frame(x.s, subs = rep(paste("S", 1:n.obs, sep = ""), nj))
    colnames(x.df) <- c("values", "items", "id")
    quiet_lmer <- purrr::quietly(lme4::lmer)
    mod.lmer <- quiet_lmer(
        values ~ 1 + (1 | id) + (1 | items),
        data = x.df,
        na.action = na.omit
    )$result
    vc <- lme4::VarCorr(mod.lmer)
    MS_id <- vc$id[1, 1]
    MS_items <- vc$items[1, 1]
    MSE <- error <- MS_resid <- (attributes(vc)$sc)^2
    MSB <- nj * MS_id + error
    MSJ <- n.obs * MS_items + error
    MSW <- error + MS_items
    return((MSB - MSE) / (MSB + (nj - 1) * MSE + nj * (MSJ - MSE) / n.obs))
}
