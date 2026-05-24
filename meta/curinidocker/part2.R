suppressPackageStartupMessages(library(here))
suppressPackageStartupMessages(library(sandwich))
suppressPackageStartupMessages(library(lmtest))
suppressPackageStartupMessages(library(quanteda))
suppressPackageStartupMessages(library(quanteda.seededlda))

load(here("rawdata/dfm.RData"))

cat("DFM version\n")
print(myDfm@version)

cat("Dimenions\n")
print(dim(myDfm))

myDict <- dictionary(list(
    multilateralism = c(
        "multilateralism",
        "comunit",
        "responsabilit",
        "alleanza",
        "alleati",
        "impegno",
        "sicurezza",
        "coalizione"
    ),
    humanitarian_dimension = c(
        "democrazia",
        "umani",
        "democrazia",
        "democratica",
        "diritto",
        "pace",
        "solidariet",
        "libert",
        "pacific*",
        "umanitaria",
        "umanitari",
        "solidal*"
    ),
    war = c(
        "guerra",
        "militare",
        "bombardamenti",
        "militari",
        "costituzione",
        "disarmo",
        "chiarezza",
        "violenza",
        "bombe",
        "rischi",
        "vittime"
    )
))

set.seed(123)

slda <- textmodel_seededlda(myDfm, myDict, residual = TRUE)
multilateralism <- rep(NA, nrow(myText))
for (i in 1:104) {
    multilateralism[i] <- slda$lda@gamma[i, ][1]
}

humanitarian_dimension <- rep(NA, nrow(myText))
for (i in 1:104) {
    humanitarian_dimension[i] <- slda$lda@gamma[i, ][2]
}

war <- rep(NA, nrow(myText))
for (i in 1:104) {
    war[i] <- slda$lda@gamma[i, ][3]
}

fit_slda <- fit[-c(1)]
fit_slda$multilateralism <- multilateralism
fit_slda$humanitarian_dimension <- humanitarian_dimension
fit_slda$war <- war

reg_data <- fit_slda

reg_data$multi100 <- reg_data$multilateralism /
    (reg_data$multilateralism + reg_data$humanitarian_dimension + reg_data$war)

glmmod <- glm(
    multi100 ~ LR + I(LR^2) + Gov + Year + as.factor(Party),
    data = reg_data,
    family = quasibinomial("logit")
)
print(coeftest(glmmod, vcov. = vcovHC(glmmod, type = "HC0")))
print(sessionInfo())
