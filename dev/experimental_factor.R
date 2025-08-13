thetas <- readRDS(here(
    "intermediate",
    "chan",
    "runs",
    "1",
    "theta",
    "theta.RDS"
))

theta_df <- thetas |> purrr::map(as.data.frame) |> purrr::list_cbind()

colnames(theta_df) <- names(thetas)
pca <- prcomp(theta_df, scale = TRUE)

eigenvalues <- pca$sdev^2

plot(eigenvalues, type = "b", xlab = "Principal Component", ylab = "Eigenvalue")
