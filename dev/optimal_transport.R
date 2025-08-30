library(here)
library(transport)
df_theta1 <- readRDS(here("dev", "1 1.RDS"))
df_theta2 <- readRDS(here("dev", "2 1.RDS"))

cost_matrix <- matrix(data = 0, nrow = ncol(df_theta1), ncol = ncol(df_theta2))

for (i in seq_len(ncol(df_theta1))) {
    for (j in seq_len(ncol(df_theta2))) {
        cost_matrix[i, j] <- (1 -
            cor(df_theta1[, i], df_theta2[, j], method = "spearman")) /
            2
    }
}

res <- purrr::map_dbl(seq_len(nrow(df_theta1)), \(x) {
    sum(
        transport::transport(
            df_theta1[x, ],
            df_theta2[x, ],
            costm = cost_matrix,
            fullreturn = TRUE
        )$primal *
            cost_matrix
    )
})

## total cost
testthat::expect_equal(sum(res), 704.82100777)
## avg cost
testthat::expect_equal(sum(res) / nrow(df_theta1), 0.3332487)
