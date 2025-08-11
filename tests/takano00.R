# Copyright (c) 2023 Ryota Takano

# In short, you are free to use, copy and distribute this file as you'd like

# Data File for "Japanese ver. of AWE-S and Purity"

# Prepared with R Studio version 2022.12.0.353
# Prepared with R version 4.2.2 (2022-10-31)

#### ==== 1. Package Install ====
# if(!require(pacman)) install.packages("pacman")
pacman::p_load (tidyr, dplyr, stringr, sjPlot, sjstats, jtools, gt, syuzhet,
                psych, rstatix, lsmeans, ggplot2, igraph,
                patchwork, emmeans, bayesplot, ggfortify, wordcloud2,
                gridExtra, lattice, mediation,rstanarm, tm,
                effectsize, ggdist, ggpp, ggsignif, skimr, descr, summarytools,
                lavaan, sem, wordcloud, ltm, ppcor, irr, rstan, estimatr
)

library (RMeCab)

# R setting
options(scipen=999)
options(contrasts = c("contr.sum", "contr.poly"))
# for Japanese
#par(family= "HiraKakuProN-W3")

# Rapid computation
rstan_options (auto_write = T)
options (mc.cores = parallel::detectCores())

#### ==== 2. Data Import & Pre-processing ====
#### ==== 2-1. data import ====
pilotdata <- read.csv("data_pilot_cleaned.csv") 
pilotdata <- pilotdata %>% 
  dplyr::mutate (ID = rownames(.)) %>% 
  dplyr::select(ID, ins_1:age, -AWE.S_c) %>% 
  dplyr::mutate_at (vars(starts_with("AWE")), as.numeric) %>% 
  dplyr::mutate (time = (AWES_1+AWES_2+AWES_3+AWES_4+AWES_5)/5,
                 selfLoss = (AWES_6+AWES_7+AWES_8+AWES_9+AWES_10)/5,
                 connectedness = (AWES_11+AWES_12+AWES_13+AWES_14+AWES_15)/5,
                 vastness = (AWES_16+AWES_17+AWES_18+AWES_19+AWES_20)/5,
                 physiological = (AWES_21+AWES_22+AWES_23+AWES_24+AWES_25)/5,
                 accommodation = (AWES_26+AWES_27+AWES_28+AWES_29+AWES_30)/5,
                 AWES = (time + selfLoss + connectedness + vastness + physiological +
                           accommodation)/6,
                 age = as.numeric(age))

data <- read.csv("data_cleaned.csv") 
data <- data %>% 
  dplyr::mutate (ID = rownames(.)) %>% 
  dplyr::select(ID, DPES_1:age, -AWES_c) %>% 
  dplyr::mutate_at (vars(starts_with("AWE")), as.numeric) %>% 
  dplyr::mutate_at (vars(starts_with("DPES")), as.numeric) %>% 
  dplyr::mutate_at (vars(age), as.numeric) %>% 
  dplyr::mutate (time = (AWES_1+AWES_2+AWES_3+AWES_4+AWES_5)/5,
                 selfLoss = (AWES_6+AWES_7+AWES_8+AWES_9+AWES_10)/5,
                 connectedness = (AWES_11+AWES_12+AWES_13+AWES_14+AWES_15)/5,
                 vastness = (AWES_16+AWES_17+AWES_18+AWES_19+AWES_20)/5,
                 physiological = (AWES_21+AWES_22+AWES_23+AWES_24+AWES_25)/5,
                 accommodation = (AWES_26+AWES_27+AWES_28+AWES_29+AWES_30)/5,
                 AWES = (time + selfLoss + connectedness + vastness + physiological +
                           accommodation)/6) %>% 
  dplyr::mutate (joy = (DPES_1 + DPES_2 + DPES_5 + DPES_7 + DPES_12 + DPES_18)/6,
                 amusement = (DPES_3 + DPES_6 + DPES_8 + DPES_26 + DPES_38)/5, 
                 awe = (DPES_4 + DPES_16 + DPES_17 + DPES_22 + DPES_31 + DPES_36)/6,
                 contentment = (DPES_9 + DPES_10 + DPES_20 + DPES_24 + DPES_29)/5,
                 love = (DPES_11 + DPES_19 + DPES_21 + DPES_25 + DPES_28 + DPES_34)/6,
                 pride = (DPES_13 + DPES_15 + DPES_23 + DPES_27 + DPES_33)/5,
                 compassion = (DPES_14 + DPES_30 + DPES_32 + DPES_35 + DPES_37)/5) %>% 
  dplyr::mutate (vastness2 = ifelse (vastness >= 6.20, 1, 0),
                 AWES2 = (time + selfLoss + connectedness + vastness2 + physiological +
                            accommodation)/6) 

#### ==== 2-2. descriptive statistics ====
# plot
describe(pilotdata %>% dplyr::select(age))
table (pilotdata$gender)

# main
describe(data %>% dplyr::select(age))
table (data$gender)

#### ==== 2-3. Compare with Yaden et al. (2019) ====
n_J <- 452
n_O <- 636
df <- n_J + n_O - 2

# Time factor
mean_time_J <- 4.83
mean_time_O <- 4.83

sd_time_J <- 1.25
sd_time_O <- 1.46

time_t_value <- (mean_time_J - mean_time_O) / sqrt((sd_time_J^2/n_J) + (sd_time_O^2/n_O))
time_p_value <- 2 * pt(abs(time_t_value), df = df, lower.tail = FALSE)

time_t_value
df
time_p_value

# Self-loss factor
mean_selfLoss_J <- 4.76
mean_selfLoss_O <- 4.35

sd_selfLoss_J <- 1.16
sd_selfLoss_O <- 1.60

selfLoss_t_value <- (mean_selfLoss_J - mean_selfLoss_O) / sqrt((sd_selfLoss_J^2/n_J) + (sd_selfLoss_O^2/n_O))
selfLoss_p_value <- 2 * pt(abs(selfLoss_t_value), df = df, lower.tail = FALSE)

selfLoss_t_value
df
selfLoss_p_value

# Connectedness factor
mean_connectedness_J <- 3.96
mean_connectedness_O <- 4.99

sd_connectedness_J <- 1.44
sd_connectedness_O <- 1.43

connectedness_t_value <- (mean_connectedness_J - mean_connectedness_O) / sqrt((sd_connectedness_J^2/n_J) + (sd_connectedness_O^2/n_O))
connectedness_p_value <- 2 * pt(abs(connectedness_t_value), df = df, lower.tail = FALSE)

connectedness_t_value
df
connectedness_p_value

# Vastness factor
mean_vastness_J <- 5.97
mean_vastness_O <- 5.63

sd_vastness_J <- 1.03
sd_vastness_O <- 1.22

vastness_t_value <- (mean_vastness_J - mean_vastness_O) / sqrt((sd_vastness_J^2/n_J) + (sd_vastness_O^2/n_O))
vastness_p_value <- 2 * pt(abs(vastness_t_value), df = df, lower.tail = FALSE)

vastness_t_value
df
vastness_p_value

# Physiological factor
mean_physiological_J <- 4.85
mean_physiological_O <- 5.02

sd_physiological_J <- 1.18
sd_physiological_O <- 1.36

physiological_t_value <- (mean_physiological_J - mean_physiological_O) / sqrt((sd_physiological_J^2/n_J) + (sd_physiological_O^2/n_O))
physiological_p_value <- 2 * pt(abs(physiological_t_value), df = df, lower.tail = FALSE)

physiological_t_value
df
physiological_p_value

# Accommodation factor
mean_accommodation_J <- 4.85
mean_accommodation_O <- 4.76

sd_accommodation_J <- 1.18
sd_accommodation_O <- 1.40

accommodation_t_value <- (mean_accommodation_J - mean_accommodation_O) / sqrt((sd_accommodation_J^2/n_J) + (sd_accommodation_O^2/n_O))
accommodation_p_value <- 2 * pt(abs(accommodation_t_value), df = df, lower.tail = FALSE)

accommodation_t_value
df
accommodation_p_value

#### ==== 3. Correlation Analyses ====
data %>% 
  dplyr::select (awe, amusement, joy, compassion, love, pride, 
                 contentment, time, selfLoss, 
                 connectedness, vastness, physiological,
                 accommodation, AWES, vastness2, AWES2) %>% 
  tab_corr(., p.numeric = TRUE, triangle = "lower")


#### ==== 4. Regression Analyses ====
#### ==== 4-1. AWES ~ DPES ====
# Standardization
data_s <- data %>% 
  dplyr::mutate(AWES = scale (AWES), time = scale (time), age = scale(age),
                selfLoss = scale (selfLoss), connectedness = scale (connectedness),
                vastness = scale (vastness), physiological = scale (physiological),
                accommodation = scale (accommodation), awe = scale (awe),
                amusement = scale (amusement), joy = scale (joy),
                compassion = scale (compassion), love = scale (love),
                pride = scale (pride), contentment = scale (contentment))
summary(estimatr::lm_robust(
  data = data_s, se_type = "HC0",
  AWES ~ awe + amusement + joy + compassion + love + pride + contentment))

summary(estimatr::lm_robust(
  data = data_s, se_type = "HC0",
  time ~ awe + amusement + joy + compassion + love + pride + contentment))

summary(estimatr::lm_robust(
  data = data_s, se_type = "HC0",
  selfLoss ~ awe + amusement + joy + compassion + love + pride + contentment))

summary(estimatr::lm_robust(
  data = data_s, se_type = "HC0",
  connectedness ~ awe + amusement + joy + compassion + love + pride + contentment))

summary(estimatr::lm_robust(
  data = data_s, se_type = "HC0",
  vastness ~ awe + amusement + joy + compassion + love + pride + contentment))

summary(estimatr::lm_robust(
  data = data_s, se_type = "HC0",
  physiological ~ awe + amusement + joy + compassion + love + pride + contentment))

summary(estimatr::lm_robust(
  data = data_s, se_type = "HC0",
  accommodation ~ awe + amusement + joy + compassion + love + pride + contentment))

# check multicollinearity
performance::check_collinearity(
  estimatr::lm_robust(
    data = data_s, se_type = "HC0",
    AWES ~ awe + amusement + joy + compassion + love + pride + contentment))


#### ==== 5. Factor Analyses ====
#### ==== 5-1. AWE-S ====
# Bind main and pilot data for factor analyses
data_awesfactor <- data %>% 
  dplyr::select (starts_with("AWES"), time, selfLoss, 
                 connectedness, vastness, physiological, accommodation)
pilotdata_awesfactor <- pilotdata %>% 
  dplyr::select (starts_with("AWES"), time, selfLoss, 
                 connectedness, vastness, physiological, accommodation)
data_awesfactor <- bind_rows(data_awesfactor, pilotdata_awesfactor)
describe(data_awesfactor)

model <- "
f1 =~ AWES_1 + AWES_2 + AWES_3 + AWES_4 + AWES_5
f2 =~ AWES_6 + AWES_7 + AWES_8 + AWES_9 + AWES_10
f3 =~ AWES_11 + AWES_12 + AWES_13 + AWES_14 + AWES_15
f4 =~ AWES_16 + AWES_17 + AWES_18 + AWES_19 + AWES_20
f5 =~ AWES_21 + AWES_22 + AWES_23 + AWES_24 + AWES_25
f6 =~ AWES_26 + AWES_27 + AWES_28 + AWES_29 + AWES_30
"

fit <- lavaan::cfa(model, data=data_awesfactor, std.lv=T)

summary(fit, standardized=TRUE, fit.measures = TRUE)
fitMeasures (fit)

data_awesfactor %>% dplyr::select(AWES_1,AWES_2,AWES_3,AWES_4,AWES_5) %>% 
  ltm::cronbach.alpha()

data_awesfactor %>% dplyr::select(AWES_6,AWES_7,AWES_8,AWES_9,AWES_10) %>% 
  ltm::cronbach.alpha()

data_awesfactor %>% dplyr::select(AWES_11,AWES_12,AWES_13,AWES_14,AWES_15) %>% 
  ltm::cronbach.alpha()

data_awesfactor %>% dplyr::select(AWES_16,AWES_17,AWES_18,AWES_19,AWES_20) %>% 
  ltm::cronbach.alpha()

data_awesfactor %>% dplyr::select(AWES_21,AWES_22,AWES_23,AWES_24,AWES_25) %>% 
  ltm::cronbach.alpha()

data_awesfactor %>% dplyr::select(AWES_26,AWES_27,AWES_28,AWES_29,AWES_30) %>% 
  ltm::cronbach.alpha()

#### ==== 5-2. DPES ====
model_dpes <- "
f1 =~ DPES_1 + DPES_2 + DPES_5 + DPES_7 + DPES_12 + DPES_18
f2 =~ DPES_3 + DPES_6 + DPES_8 + DPES_26 + DPES_38
f3 =~ DPES_4 + DPES_16 + DPES_17 + DPES_22 + DPES_31 + DPES_36
f4 =~ DPES_9 + DPES_10 + DPES_20 + DPES_24 + DPES_29
f5 =~ DPES_11 + DPES_19 + DPES_21 + DPES_25 + DPES_28 + DPES_34
f6 =~ DPES_13 + DPES_15 + DPES_23 + DPES_27 + DPES_33
f7 =~ DPES_14 + DPES_30 + DPES_32 + DPES_35 + DPES_37
"
# joy, amusement, awe, contentment, love, pride, compassion
fit_dpes <- lavaan::cfa(model_dpes, data=data, std.lv=T)

summary(fit_dpes, standardized=TRUE, fit.measures = TRUE)
fitMeasures (fit_dpes)

data %>% dplyr::select(DPES_1,DPES_2,DPES_5,DPES_7,DPES_12,DPES_18) %>% 
  ltm::cronbach.alpha()

data %>% dplyr::select(DPES_3,DPES_6,DPES_8,DPES_26,DPES_38) %>% 
  ltm::cronbach.alpha()

data %>% dplyr::select(DPES_4,DPES_16,DPES_17,DPES_22,DPES_31,DPES_36) %>% 
  ltm::cronbach.alpha()

data %>% dplyr::select(DPES_9,DPES_10,DPES_20,DPES_24,DPES_29) %>% 
  ltm::cronbach.alpha()

data %>% dplyr::select(DPES_11,DPES_19,DPES_21,DPES_25,DPES_28,DPES_34) %>% 
  ltm::cronbach.alpha()

data %>% dplyr::select(DPES_13,DPES_15,DPES_23,DPES_27,DPES_33) %>% 
  ltm::cronbach.alpha()

data %>% dplyr::select(DPES_14,DPES_30,DPES_32,DPES_35,DPES_37) %>% 
  ltm::cronbach.alpha()

#### ==== 6. Test-retest Reliability ====
data_rere <- read.csv("data_testretest.csv")
describe(data_rere$age.x)
table (data_rere$gender.x)

irr::icc(data_rere %>% dplyr::select(AWES, AWESRe), "twoway", "agreement")
irr::icc(data_rere %>% dplyr::select(time, timeRe), "twoway", "agreement")
irr::icc(data_rere %>% dplyr::select(selfLoss, selfLossRe), "twoway", "agreement")
irr::icc(data_rere %>% dplyr::select(connectedness, connectednessRe), "twoway", "agreement")
irr::icc(data_rere %>% dplyr::select(vastness, vastnessRe), "twoway", "agreement")
irr::icc(data_rere %>% dplyr::select(physiological, physiologicalRe), "twoway", "agreement")
irr::icc(data_rere %>% dplyr::select(accommodation, accommodationRe), "twoway", "agreement")

#### ==== 7. STM ====
pacman::p_load (RMeCab, tm, topicmodels, ldatuning, SnowballC, tidytext, LDAvis,
                stm, magrittr, stringr, tidytext, dplyr, tidyr, topicmodels,
                text2vec, showtext)

docDF_toBoW <- function(doc_df){
  doc_df <- doc_df %>% dplyr::mutate(Index = row_number()) #
  
  dfVocab <- doc_df %>% dplyr::select(TERM , POS1 , POS2 , Index)
  vecVocab <- dfVocab$TERM
  
  doc_n <- doc_df %>% dplyr::select(starts_with( "Row")) %>% ncol 
  doc_info <- list() 
  
  for( i in 1:doc_n){
    row_tgt <- paste0( "Row", i)
    row_q <- rlang::parse_expr(row_tgt)
    
    tgt_df <- doc_df[, c("Index",row_tgt )]
    term_cnt <- tgt_df %>% filter( !!(row_q) > 0 )
    
    doc_bow <- term_cnt %>% as.matrix() %>% t()
    doc_info[[i]] <- doc_bow
  }
  
  return( list(BoW = doc_info,
               Vocab = vecVocab,
               dfVocab = dfVocab
  ))
} #function

data_nlp_sum <- bind_rows(data %>%
                            dplyr::select(ins_1, gender, age, time, selfLoss,
                                          connectedness, vastness, physiological,
                                          accommodation, AWES, ID),
                          pilotdata %>%
                            dplyr::select(ins_1, gender, age, time, selfLoss,
                                          connectedness, vastness, physiological,
                                          accommodation, AWES, ID))

# Restricted to adjectives, verbs and nouns with at least three occurrences
retTerm2 <- docDF(data_nlp_sum, "ins_1" , type = 1,
                  pos = c("動詞","名詞", "形容詞"), minFreq = 3)

# screen
retTerm2_v2 <- retTerm2 %>% 
  dplyr::filter (!(POS2 %in% c("数", "代名詞","接尾","非自立"))) %>% 
  dplyr::filter (!(TERM %in% c (",", "ない", "ある", "いい", "いう",
                                "おる", "くだ", "しれる", "やる")))
retBoW2_v2 <- docDF_toBoW(retTerm2_v2)
retBoW2_v2$BoW %>% head()
retBoW2_v2$Vocab %>% sample(10)

# pre-process
prep_JBoW20 <- stm::prepDocuments(
  retBoW2_v2$BoW,
  vocab = retBoW2_v2$Vocab,
  meta = data_nlp_sum,
  lower.thresh = 3,
  upper.thresh = 100
) 

# plot searchK
storage_20 <- stm::searchK(
  prep_JBoW20$documents,
  prep_JBoW20$vocab,
  K = seq (2, 20, 1),
  prevalence =~ time + selfLoss + connectedness + vastness + physiological + accommodation,
  data = prep_JBoW20$meta,
)
plot (storage_20)


# STM K = 7
JSTM_k7 <- stm::stm (
  documents = prep_JBoW20$documents,
  K = 7,
  data = prep_JBoW20$meta,
  vocab = prep_JBoW20$vocab,
  prevalence =~ time + selfLoss + connectedness + vastness + physiological + accommodation
)

JSTM_k7 %>% stm::plot.STM(
  type = "labels", 
  n = 20,
# family = "HiraKakuProN-W3",
  width = 100)

prepk7 <- stm::estimateEffect(
  1:7 ~ time + selfLoss + connectedness + vastness + physiological + accommodation, 
  JSTM_k7, meta = prep_JBoW20$meta, uncertainty = "Global")

stm::labelTopics(JSTM_k7, n = 20)
summary(prepk7)

stm::labelTopics(JSTM_k7, 1)
summary(prepk7, topics=1)

stm::labelTopics(JSTM_k7, 2)
summary(prepk7, topics=2)

stm::labelTopics(JSTM_k7, 3)
summary(prepk7, topics=3)

stm::labelTopics(JSTM_k7, 4)
summary(prepk7, topics=4)

stm::labelTopics(JSTM_k7, 5)
summary(prepk7, topics=5)

stm::labelTopics(JSTM_k7, 6)
summary(prepk7, topics=6)

stm::labelTopics(JSTM_k7, 7)
summary(prepk7, topics=7)

# mod.out.corr_k7 <- topicCorr(JSTM_k7)
# plot(mod.out.corr_k7)
plot(JSTM_k7$convergence$bound, type = "l",
     ylab = "Approximate Objective",
     main = "Convergence")

plot(JSTM_k7, type = "summary", xlim = c(0, .4),
#    family = "HiraKakuProN-W3")
)
summary(JSTM_k7$theta)
# 1: 0.125658, 2: 0.161959, 3: 0.121626, 4: 0.1095447, 5: 0.217176,
# 6: 0.149680, 7: 0.114357


# Plot the parameter estimates of the effects of AWE-S
modelk7_1 <- summary(prepk7, topics = 1)$tables %>% data.frame() 
modelk7_1_df<- cbind(rownames(modelk7_1), modelk7_1) %>% 
  dplyr::rename (variables = "rownames(modelk7_1)") %>% 
  dplyr::mutate (lower = Estimate - (1.96*Std..Error),
                 upper = Estimate + (1.96*Std..Error),
                 topics = "Spirituality",
                 topicnum = 1,
                 prop = 0.125658)
rownames(modelk7_1_df) <- 1:nrow(modelk7_1_df) 

modelk7_2 <- summary(prepk7, topics = 2)$tables %>% data.frame() 
modelk7_2_df<- cbind(rownames(modelk7_2), modelk7_2) %>% 
  dplyr::rename (variables = "rownames(modelk7_2)") %>% 
  dplyr::mutate (lower = Estimate - (1.96*Std..Error),
                 upper = Estimate + (1.96*Std..Error),
                 topics = "Threat",
                 topicnum = 2,
                 prop = 0.161959)
rownames(modelk7_2_df) <- 1:nrow(modelk7_2_df)

modelk7_3 <- summary(prepk7, topics = 3)$tables %>% data.frame() 
modelk7_3_df<- cbind(rownames(modelk7_3), modelk7_3) %>% 
  dplyr::rename (variables = "rownames(modelk7_3)") %>% 
  dplyr::mutate (lower = Estimate - (1.96*Std..Error),
                 upper = Estimate + (1.96*Std..Error),
                 topics = "Spatiality",
                 topicnum = 3,
                 prop = 0.121626)
rownames(modelk7_3_df) <- 1:nrow(modelk7_3_df)

modelk7_4 <- summary(prepk7, topics = 4)$tables %>% data.frame() 
modelk7_4_df<- cbind(rownames(modelk7_4), modelk7_4) %>% 
  dplyr::rename (variables = "rownames(modelk7_4)") %>% 
  dplyr::mutate (lower = Estimate - (1.96*Std..Error),
                 upper = Estimate + (1.96*Std..Error),
                 topics = "Universe",
                 topicnum = 4,
                 prop = 0.1095447)
rownames(modelk7_4_df) <- 1:nrow(modelk7_4_df)

modelk7_5 <- summary(prepk7, topics = 5)$tables %>% data.frame() 
modelk7_5_df<- cbind(rownames(modelk7_5), modelk7_5) %>% 
  dplyr::rename (variables = "rownames(modelk7_5)") %>% 
  dplyr::mutate (lower = Estimate - (1.96*Std..Error),
                 upper = Estimate + (1.96*Std..Error),
                 topics = "Scenery",
                 topicnum = 5,
                 prop = 0.217176)
rownames(modelk7_5_df) <- 1:nrow(modelk7_5_df)

modelk7_6 <- summary(prepk7, topics = 6)$tables %>% data.frame() 
modelk7_6_df<- cbind(rownames(modelk7_6), modelk7_6) %>% 
  dplyr::rename (variables = "rownames(modelk7_6)") %>% 
  dplyr::mutate (lower = Estimate - (1.96*Std..Error),
                 upper = Estimate + (1.96*Std..Error),
                 topics = "Humanity",
                 topicnum = 6,
                 prop = 0.149680)
rownames(modelk7_6_df) <- 1:nrow(modelk7_6_df)

modelk7_7 <- summary(prepk7, topics = 7)$tables %>% data.frame() 
modelk7_7_df<- cbind(rownames(modelk7_7), modelk7_7) %>% 
  dplyr::rename (variables = "rownames(modelk7_7)") %>% 
  dplyr::mutate (lower = Estimate - (1.96*Std..Error),
                 upper = Estimate + (1.96*Std..Error),
                 topics = "Aesthetics",
                 topicnum = 7,
                 prop = 0.114357)
rownames(modelk7_7_df) <- 1:nrow(modelk7_7_df)

modelk7_df <- bind_rows(modelk7_1_df, modelk7_2_df) %>% 
  bind_rows(., modelk7_3_df) %>% 
  bind_rows(., modelk7_4_df) %>% 
  bind_rows(., modelk7_5_df) %>% 
  bind_rows(., modelk7_6_df) %>% 
  bind_rows(., modelk7_7_df) 

Plot_time_k7 <- 
  ggplot(modelk7_df %>% filter (variables == "time"), 
         aes(x = Estimate, y = reorder(topics, topicnum*(-1)))) +
  geom_vline(aes(xintercept = 0), linetype = "longdash") +
  geom_errorbarh(aes(xmin = lower, xmax = upper), height = 0.1) +
  geom_point(aes(x = Estimate, size = prop)) +
  theme(axis.title.y = element_blank()) +
  labs (size = "Expected Topic Proportion")+
  ylab("Topic") + xlab("Estimate") + ggtitle("Time") +
  labs (tag = "A") +
  theme(axis.text.y = element_text(size = 12),
        axis.title.x = element_text(size = 12),
        legend.position = "none")+
  xlim(-0.075, 0.08)
Plot_selfLoss_k7 <- 
  ggplot(modelk7_df %>% filter (variables == "selfLoss"), 
         aes(x = Estimate, y = reorder(topics, topicnum*(-1)))) +
  geom_vline(aes(xintercept = 0), linetype = "longdash") +
  geom_errorbarh(aes(xmin = lower, xmax = upper), height = 0.1) +
  geom_point(aes(x = Estimate, size = prop)) +
  theme(axis.title.y = element_blank()) +
  labs (size = "Expected Topic Proportion")+
  ylab("Topic") + xlab("Estimate") + ggtitle("Self-loss")+
  labs (tag = "B") +
  theme(axis.text.y = element_text(size = 12),
        axis.title.x = element_text(size = 12),
        legend.position = "none")+
  xlim(-0.075, 0.08)
Plot_connectedness_k7 <- 
  ggplot(modelk7_df %>% filter (variables == "connectedness"), 
         aes(x = Estimate, y = reorder(topics, topicnum*(-1)))) +
  geom_vline(aes(xintercept = 0), linetype = "longdash") +
  geom_errorbarh(aes(xmin = lower, xmax = upper), height = 0.1) +
  geom_point(aes(x = Estimate, size = prop)) +
  theme(axis.title.y = element_blank()) +
  labs (size = "Expected Topic Proportion")+
  ylab("Topic") + xlab("Estimate") + ggtitle("Connectedness")+
  labs (tag = "C") +
  theme(axis.text.y = element_text(size = 12),
        axis.title.x = element_text(size = 12),
        legend.position = "none")+
  xlim(-0.075, 0.08)
Plot_vastness_k7 <- 
  ggplot(modelk7_df %>% filter (variables == "vastness"), 
         aes(x = Estimate, y = reorder(topics, topicnum*(-1)))) +
  geom_vline(aes(xintercept = 0), linetype = "longdash") +
  geom_errorbarh(aes(xmin = lower, xmax = upper), height = 0.1) +
  geom_point(aes(x = Estimate, size = prop)) +
  theme(axis.title.y = element_blank()) +
  labs (size = "Expected\nTopic Proportion")+
  ylab("Topic") + xlab("Estimate") + ggtitle("Vastness")+
  labs (tag = "D") +
  theme(axis.text.y = element_text(size = 12),
        axis.title.x = element_text(size = 12))+
  xlim(-0.075, 0.08)
Plot_physiological_k7 <- 
  ggplot(modelk7_df %>% filter (variables == "physiological"), 
         aes(x = Estimate, y = reorder(topics, topicnum*(-1)))) +
  geom_vline(aes(xintercept = 0), linetype = "longdash") +
  geom_errorbarh(aes(xmin = lower, xmax = upper), height = 0.1) +
  geom_point(aes(x = Estimate, size = prop)) +
  theme(axis.title.y = element_blank()) +
  labs (size = "Expected Topic Proportion")+
  ylab("Topic") + xlab("Estimate") + ggtitle("Physiological")+
  labs (tag = "E") +
  theme(axis.text.y = element_text(size = 12),
        axis.title.x = element_text(size = 12),
        legend.position = "none")+
  xlim(-0.075, 0.08)
Plot_accommodation_k7 <- 
  ggplot(modelk7_df %>% filter (variables == "accommodation"), 
         aes(x = Estimate, y = reorder(topics, topicnum*(-1)))) +
  geom_vline(aes(xintercept = 0), linetype = "longdash") +
  geom_errorbarh(aes(xmin = lower, xmax = upper), height = 0.1) +
  geom_point(aes(x = Estimate, size = prop)) +
  theme(axis.title.y = element_blank()) +
  labs (size = "Expected Topic Proportion")+
  ylab("Topic") + xlab("Estimate") + ggtitle("Accommodation")+
  labs (tag = "F") +
  theme(axis.text.y = element_text(size = 12),
        axis.title.x = element_text(size = 12),
        legend.position = "none")+
  xlim(-0.075, 0.08)

(Plot_time_k7 | Plot_selfLoss_k7) / 
  (Plot_connectedness_k7 | Plot_vastness_k7) / 
  (Plot_physiological_k7 | Plot_accommodation_k7)


thoughts1_k7 <- stm::findThoughts(
  JSTM_k7, texts = data_nlp_sum$ins_1, n = 5, topics = 1)$docs[[1]]
thoughts2_k7 <- stm::findThoughts(
  JSTM_k7, texts = data_nlp_sum$ins_1, n = 5, topics = 2)$docs[[1]]
thoughts3_k7 <- stm::findThoughts(
  JSTM_k7, texts = data_nlp_sum$ins_1, n = 5, topics = 3)$docs[[1]]
thoughts4_k7 <- stm::findThoughts(
  JSTM_k7, texts = data_nlp_sum$ins_1, n = 5, topics = 4)$docs[[1]]
thoughts5_k7 <- stm::findThoughts(
  JSTM_k7, texts = data_nlp_sum$ins_1, n = 5, topics = 5)$docs[[1]]
thoughts6_k7 <- stm::findThoughts(
  JSTM_k7, texts = data_nlp_sum$ins_1, n = 5, topics = 6)$docs[[1]]
thoughts7_k7 <- stm::findThoughts(
  JSTM_k7, texts = data_nlp_sum$ins_1, n = 5, topics = 7)$docs[[1]]

thoughts1_k7
thoughts2_k7
thoughts3_k7
thoughts4_k7
thoughts5_k7
thoughts6_k7
thoughts7_k7

