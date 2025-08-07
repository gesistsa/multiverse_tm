## 　 　 　 　 |＼　　 　 　 　 　 ／|
## 　 　 　 　 |＼＼　　 　 　 ／／|
## 　　　　 　 : 　,>　｀´￣｀´　<　 ′
## .　　　　 　 Ｖ　 　 　 　 　 　 Ｖ
## .　　　　 　 i{　●　 　 　 ●　}i
## 　　　　 　 八　 　 ､_,_, 　 　 八 　　　わけがわからないよ 
## . 　 　 　 /　个 . ＿　 ＿ . 个 ',
## 　　　＿/ 　 il 　 ,'　　　 '.　 li　 ',＿_

library(dplyr)
library(RMeCab)
library(here)
library(quanteda)

pilotdata <- read.csv(here("rawdata", "data_pilot_cleaned.csv"))
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

data <- read.csv(here("rawdata", "data_cleaned.csv"))
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


data_nlp_sum <- bind_rows(data %>%
                            dplyr::select(ins_1, gender, age, time, selfLoss,
                                          connectedness, vastness, physiological,
                                          accommodation, AWES, ID),
                          pilotdata %>%
                            dplyr::select(ins_1, gender, age, time, selfLoss,
                                          connectedness, vastness, physiological,
                                          accommodation, AWES, ID))

retTerm2 <- docDF(data_nlp_sum, "ins_1" , type = 1,
                  pos = NULL, minFreq = 1)

retTerm2 |> select(-TERM, -POS1, -POS2) |> as.matrix() |> t() -> dtm_raw

colinfo <- retTerm2 |> select(TERM, POS1, POS2)

stopifnot(nrow(colinfo) == ncol(dtm_raw))

as.dfm(dtm_raw)

library(udpipe)

japanese_model <- udpipe_load_model(here("rawdata", "japanese-gsd-ud-2.5-191206.udpipe"))

parsed_content <- udpipe_annotate(japanese_model, data_nlp_sum$ins_1)

parsed_content_df <- as.data.frame(parsed_content)
