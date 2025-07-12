args <- commandArgs(trailingOnly=TRUE)
if (length(args) == 0) {
    stop("You must provide the current run number, e.g. Rscript un02_keyatm.R 1")
}
current_run <- args[1]


library(keyATM)
library(quanteda)
library(SnowballC)
library(seededlda)
library(here)

dir.create(here(here("intermediate/un/runs", current_run)), recursive = TRUE)
stopifnot(dir.exists(here(here("intermediate/un/runs", current_run))))

sdg_keywords <- list(
    SDG1 = c("poverty", "extreme_poverty", "poor", "socioeconomic", "income", "living_standards", "living_standard"),
    SDG2 = c("hunger", "food_security", "nutrition", "agriculture", "farming", "malnutrition", "sustainable_agriculture", "food_systems", "food_system"),
    SDG3 = c("health", "wellbeing", "disease", "maternal_health", "child_mortality", "epidemic", "vaccines", "healthcare"),
    SDG4 = c("education", "literacy", "school", "primary_education", "secondary_education", "tertiary_education", "lifelong_learning", "skills_development"),
    SDG5 = c("gender_equality", "women", "girls", "empowerment", "discrimination", "female", "gender_mainstreaming", "gender_based", "gender_violence"),
    SDG6 = c("water", "sanitation", "clean_water", "drinking_water", "waste_water","wastewater", "water_resources", "water_management", "hygiene"),
    SDG7 = c("energy", "renewable_energy", "clean_energy", "sustainable_energy", "electricity", "energy_access", "energy_efficiency", "energy_security"),
    SDG8 = c("economic_growth", "employment", "decent_work", "labour", "inclusive_growth", "sustainable_growth", "labour_market", "youth_employment"),
    SDG9 = c("infrastructure", "innovation", "industrialization", "technology", "research", "development", "sustainable_industrialization","sustainable_industry", "technological_progress"),
    SDG10 = c("inequality", "inequalities", "income_inequality", "wealth_distribution", "social_inclusion", "equal_opportunity", "equal_opportunities", "discrimination", "economic_divide", "equity"),
    SDG11 = c("cities", "urban", "sustainable_cities", "urban_planning", "urban_development", "urbanisation", "urban_infrastructure", "housing"),
    SDG12 = c("sustainable_consumption", "sustainable_production", "resource_efficiency", "waste_management", "recycling", "supply_chain", "circular_economy", "responsible_consumption"),
    SDG13 = c("climate_change", "global_warming", "greenhouse_gas", "emissions", "carbon_dioxide", "climate_action", "climate_resilience", "climate_mitigation"),
    SDG14 = c("oceans", "marine", "coastal", "sea", "seas", "marine_resources", "fisheries", "aquaculture", "marine_pollution"),
    SDG15 = c("biodiversity", "ecosystems", "ecosystem", "land", "forest", "forests", "wildlife", "habitat", "deforestation", "desertification", "species"),
    SDG16 = c("peace", "justice", "institutions", "rule_law", "governance", "accountability", "transparency", "corruption", "human_rights", "violence"),
    SDG17 = c("partnership", "international_cooperation", "global_partnership",  "development_goals","development_cooperation", "financing_development", "development_finance", "trade", "technology_transfer", "capacity_building")
)


## This is not working because we stemmed first, before doing bigram in un01
## sdg_keywords_stemmed <- lapply(sdg_keywords, SnowballC::wordStem)

split_keywords <- lapply(sdg_keywords, strsplit, split = "_")

stemmed_sdg_keywords <- list()

for (i in seq_len(length(split_keywords))) {
    stemmed_sdg_keywords[[i]] <- unique(vapply(lapply(split_keywords[[i]], SnowballC::wordStem), paste, collapse = "_", FUN.VALUE = character(1)))
}

names(stemmed_sdg_keywords) <- names(sdg_keywords)

# combis
# col1: 1,2,3 = no unit, lemmatize, stem
# col2: 1,0 = stopword yes no
# col3: 1,0 = trim yes no
# col4: 1,0 = alternative model yes no
# col5: 1,2,3 = K original, alt1, alt2
# col6: 1,2,3 = iter original, alt1, alt2

combis <- expand.grid(c(1,2,3), c(1, 0), c(1, 0), c(1, 0), c(1,2,3), c(1,2,3)) %>% as.matrix
attr(combis, "dimnames") <- NULL

k <- c(1, 3, 5)
iter_keyATM <- c(1500, round(1500 * 0.8), round(1500 * 1.2))
iter_seededlda <- c(2000, round(2000 * 0.8), round(2000 * 1.2)) ## wont do much



## stole from keyATM:::check_keywords, modified to return missing keywords topics
check_keywords <- function(docs, keywords) {
    info <- list()
    
    if (is.null(docs$wd_names)) {
        info$wd_names <- unique(unlist(docs$W_raw, use.names = FALSE, recursive = FALSE))
        keyATM:::check_vocabulary(info$wd_names)
    } else {
        info$wd_names <- docs$wd_names
    }

    unique_words <- info$wd_names
    
    # Prune keywords that do not appear in the corpus
    keywords_flat <- unlist(keywords, use.names = FALSE, recursive = FALSE)
    non_existent <- keywords_flat[!keywords_flat %in% unique_words]
    keywords <- lapply(keywords, function(x) {x[!x %in% non_existent]})
    # Check there is at least one keywords in each topic
    num_keywords <- unlist(lapply(keywords, length))
    check_zero <- which(as.vector(num_keywords) != 0)
    return(check_zero)
}

for (i in seq_len(nrow(combis))) {
    hash <- rlang::hash(combis[i, 1:3])
    current_dfm <- readRDS(here("intermediate/un", paste0(hash, ".RDS")))

    if (combis[i, 1] == 3) {
        current_dict <- stemmed_sdg_keywords
    } else {
        current_dict <- sdg_keywords
    }
    current_k <- k[combis[i, 5]]
    if (combis[i, 4] == 0) { ## original: keyATM
        current_iter <- iter_seededlda[combis[i, 6]]
        ATM_docs <- keyATM_read(current_dfm)
        ## to prevent all words missing for a topic
        current_dict <- current_dict[check_keywords(ATM_docs, current_dict)]
        mod <- keyATM(docs            = ATM_docs,    
                      no_keyword_topics = current_k,
                      keywords          = current_dict, 
                      model             = "base",  
                      options           = list(iterations = current_iter,
                                               prune = TRUE))
    } else { ## alternative: seededLDA
        current_iter <- iter_keyATM[combis[i,6]]
        mod <- textmodel_seededlda(x = current_dfm,
                                   dictionary = quanteda::dictionary(current_dict),
                                   valuetype = "fixed",
                                   max_iter = current_iter,
                                   residual = current_k,
                                   verbose = TRUE
        )
    }
    current_hash <- rlang::hash(combis[i,])
    saveRDS(mod, here("intermediate/un/runs", current_run, paste0(current_hash, ".RDS")))
}
