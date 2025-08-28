tmmv.calculate_icc <- function(x) {
    if (length(unique(x)) == 1) {
        ## all the same
        return(1)
    }
    x <- purrr::map(x, as.data.frame) |>
        purrr::quietly(purrr::list_cbind)() |>
        purrr::chuck("result")
    n.obs <- nrow(x)
    nj <- ncol(x)
    x.s <- stack(x)
    x.df <- data.frame(x.s, subs = rep(paste("S", 1:n.obs, sep = ""), nj))
    colnames(x.df) <- c("values", "items", "id") #this makes it simpler to understand
    ## quiet_lmer <- purrr::quietly(lme4::lmer)
    mod.lmer <- lme4::lmer(
        values ~ 1 + (1 | id) + (1 | items),
        data = x.df,
        na.action = na.omit
    )
    vc <- lme4::VarCorr(mod.lmer)
    MS_id <- vc$id[1, 1]
    MS_items <- vc$items[1, 1]

    MSE <- error <- MS_resid <- (attributes(vc)$sc)^2
    ## MS.df <- data.frame(variance= c(MS_id ,MS_items, MS_resid,NA))
    ## rownames(MS.df) <- c("ID","Items", "Residual","Total")

    ## MS.df["Total",]  <- sum(MS.df[1:3,1],na.rm=TRUE)
    ## MS.df["Percent"] <- MS.df/MS.df["Total",1]
    ## lmer.MS <- MS.df  #save these
    #convert to AOV equivalents  #changed to a cleaner form 8/18/21
    MSB <- nj * MS_id + error
    MSJ <- n.obs * MS_items + error
    MSW <- error + MS_items
    (MSB - MSE) / (MSB + (nj - 1) * MSE + nj * (MSJ - MSE) / n.obs)
}
