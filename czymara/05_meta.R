library(here)
library(dplyr)

results <- read.csv(here("results", "aggregated", "czymara", "1.csv"))

overall_estimate <- mean(results$Estimate)

tok <- results |> group_by(token_normalization) |> summarise(est = mean(Estimate)) |> rename(condition = token_normalization)

stop <- results |> group_by(stopword_removal) |> summarise(est = mean(Estimate)) |> rename(condition = stopword_removal) |> mutate(condition = case_when(condition ~ "Stop Yes", !condition ~ "Stop No"))

trim <- results |> group_by(trimming) |> summarize(est = mean(Estimate)) |> rename(condition = trimming) |> mutate(condition = case_when(condition ~ "Trimming Yes", !condition ~ "Trimming No"))

alt <- results |> group_by(alternative_model) |> summarize(est = mean(Estimate)) |> rename(condition = alternative_model) |> mutate(condition = case_when(condition ~ "Alternative_Model Yes", !condition ~ "Alternative_Model No"))

k <- results |> group_by(k_setting) |> summarize(est = mean(Estimate)) |> rename(condition = k_setting) |> mutate(condition = case_when(condition == 1 ~ "K 1", condition == 2 ~ "K 2", condition == 3 ~ "K 3"))

iter <- results |> group_by(iteration_setting) |> summarize(est = mean(Estimate)) |> rename(condition = iteration_setting) |> mutate(condition = case_when(condition == 1 ~ "iter 1", condition == 2 ~ "iter 2", condition == 3 ~ "iter 3"))

rbind(tok, stop, trim, alt, k, iter) |> ggplot(aes(est, condition)) + geom_point() + geom_vline(aes(xintercept = overall_estimate), linetype = 2)


