suppressPackageStartupMessages(library(here))
suppressPackageStartupMessages(library(sandwich))
suppressPackageStartupMessages(library(lmtest))

reg_data <- read.csv(here("rawdata/scores_slda.csv"), stringsAsFactors = FALSE)

reg_data$multi100 <- reg_data$multilateralism /
    (reg_data$multilateralism + reg_data$humanitarian_dimension + reg_data$war)

glmmod <- glm(
    multi100 ~ LR + I(LR^2) + Gov + Year + as.factor(Party),
    data = reg_data,
    family = quasibinomial("logit")
)
print(coeftest(glmmod, vcov. = vcovHC(glmmod, type = "HC0")))
print(sessionInfo())
