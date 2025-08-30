library(here)
library(transport)
df_theta1 <- readRDS(here("dev", "1 1.RDS"))
df_theta2 <- readRDS(here("dev", "2 1.RDS"))

rho <- matrix(data = 0, nrow = ncol(df_theta1), ncol = ncol(df_theta2))

for (i in seq_len(ncol(df_theta1))) {
    for (j in seq_len(ncol(df_theta2))) {
        rho[i, j] <- cor(df_theta1[, i], df_theta2[, j], method = "spearman")
    }
}

C <- (1 - rho) / 2

i <- 1


res <- purrr::map_dbl(seq_len(nrow(df_theta1)), \(x) {
    sum(
        transport(
            df_theta1[x, ],
            df_theta2[x, ],
            costm = C,
            fullreturn = TRUE
        )$primal *
            C
    )
})

sum(res)

sum(res) / nrow(df_theta1)
