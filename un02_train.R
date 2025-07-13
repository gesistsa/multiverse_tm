library(here)

args <- commandArgs(trailingOnly=TRUE)
if (length(args) == 0) {
    stop("You must provide the current run number, e.g. Rscript un02_train.R 1")
}
current_run <- args[1]

if (current_run == "--debug") {
    DEBUG_MODE <- TRUE
    output_dir <- here("debug/un/runs/1")
    unlink(output_dir, recursive = TRUE, force = TRUE)
    cat("DEBUG MODE ENABLED. Please check the artefacts in debug/un/runs/1 \n")
} else {
    DEBUG_MODE <- FALSE
    output_dir <- here("intermediate/un/runs", current_run)
}

library(keyATM)
library(quanteda)
library(SnowballC)
library(seededlda)
library(purrr)

dir.create(output_dir, recursive = TRUE)
stopifnot(dir.exists(output_dir))

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
    stemmed_sdg_keywords[[i]] <- unique(vapply(lapply(split_keywords[[i]], SnowballC::wordStem),
                                               paste, collapse = "_",
                                               FUN.VALUE = character(1)))
}

names(stemmed_sdg_keywords) <- names(sdg_keywords)

settings <- expand.grid(token_normalization = c("none","lemmatization","stemming"),
                        stopword_removal = c(TRUE, FALSE),
                        trimming = c(TRUE, FALSE),
                        alternative_model = c(TRUE, FALSE),
                        k_setting = c(1,2,3), #K original, alt1, alt2
                        iteration_setting = c(1,2,3), #iter original, alt1, alt2
                        stringsAsFactors = FALSE) |>
    purrr::transpose()

if (DEBUG_MODE) {
    settings <- sample(settings, 10)
    cat("DEBUG MODE: Only 10 randomly selected settings will be checked.\n")
    cat("Rerun if you want more checks.\n")
}

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

train_model <- function(setting, output_dir, sdg_keywords, stemmed_sdg_keywords, DEBUG_MODE, .fix_seed = NULL, .return_output = FALSE) {
    dfm_filename <- paste0(rlang::hash(setting[1:3]), ".RDS")
    if (!DEBUG_MODE) {
        dfm_dir <- "intermediate/un"
    } else {
        print(setting)
        dfm_dir <- "debug/un"
    }
    current_dfm <- readRDS(here(dfm_dir, dfm_filename))
    if (setting$token_normalization == "stemming") {
        current_dict <- stemmed_sdg_keywords        
    } else {
        current_dict <- sdg_keywords        
    }
    k <- c(1, 3, 5)
    iter_keyATM <- c(1500, round(1500 * 0.8), round(1500 * 1.2))
    iter_seededlda <- c(2000, round(2000 * 0.8), round(2000 * 1.2))
    current_k <- k[setting$k_setting]

    # find fully pruned topics
    ATM_docs <- keyATM_read(current_dfm)
    available_topics <- check_keywords(ATM_docs, current_dict)
    if (DEBUG_MODE) {
        cat("Available topics: ", length(available_topics), "\n")
    }
    n_fully_pruned_topics <- length(current_dict) - length(available_topics)
    if (n_fully_pruned_topics > 0) {
        # compensate the fully pruned topics by adding it to the current_k
        current_k <- current_k + n_fully_pruned_topics        
        current_dict <- current_dict[available_topics]
    }
    if (!setting$alternative_model) {
        current_iter <- iter_keyATM[setting$iteration_setting]
    } else {
        current_iter <- iter_seededlda[setting$iteration_setting]        
    }
    if (DEBUG_MODE) {
        cat("DEBUG MODE: Iteration setting is 100 (min. keyATM), should be: ", current_iter, "\n")
        current_iter <- 100
    }
    if (is.null(.fix_seed)) {
        random_seed <- sample(-65535:65536, 1)
    } else {
        random_seed <- .fix_seed
    }
    if (DEBUG_MODE) {
        cat("Current seed: ", random_seed, "\n")
    }
    output <- list()
    output$random_seed <- random_seed
    output$setting <- setting
    set.seed(random_seed)
    if (!setting$alternative_model) {
        output$mod <- keyATM(docs = ATM_docs,    
                      no_keyword_topics = current_k,
                      keywords = current_dict, 
                      model = "base",  
                      options = list(iterations = current_iter,
                                     prune = TRUE,
                                     verbose = DEBUG_MODE))
    } else {
        output$mod <- textmodel_seededlda(x = current_dfm,
                                          dictionary = quanteda::dictionary(current_dict),
                                          valuetype = "fixed",
                                          max_iter = current_iter,
                                          residual = current_k,
                                          verbose = DEBUG_MODE)
    }
    if (.return_output) {
        return(output)
    }
    current_hash <- rlang::hash(setting)
    saveRDS(output, file.path(output_dir, paste0(current_hash, ".RDS")))
}

purrr::walk(settings, train_model,
            output_dir = output_dir,
            sdg_keywords = sdg_keywords,
            stemmed_sdg_keywords = stemmed_sdg_keywords,
            DEBUG_MODE = DEBUG_MODE,
            .progress = !DEBUG_MODE)

if (DEBUG_MODE) {
    library(testthat)
    for (setting in settings) {
        current_hash <- rlang::hash(setting)
        testthat::expect_true(file.exists(file.path(output_dir, paste0(current_hash, ".RDS"))))
        output <- readRDS(file.path(output_dir, paste0(current_hash, ".RDS")))
        if (setting$alternative_model) {
            testthat::expect_true("textmodel_lda" %in% class(output$mod))
        } else {
            testthat::expect_true("keyATM_output" %in% class(output$mod))
            n_theta <- ncol(output$mod$theta)
        }
        expected_k <- c(1, 3, 5)[setting$k_setting] + length(sdg_keywords)
        expect_equal(expected_k, ncol(output$mod$theta))
        ## can't test iter
    }
    ## check reproducibility; only twice
    cat("Reproducibility check \n")
    repro_settings <- sample(settings, 2)
    for (setting in repro_settings) {
        current_hash <- rlang::hash(setting)
        testthat::expect_true(file.exists(file.path(output_dir, paste0(current_hash, ".RDS"))))
        output <- readRDS(file.path(output_dir, paste0(current_hash, ".RDS")))
        new_output <- train_model(setting,
                                  output_dir = output_dir,
                                  sdg_keywords = sdg_keywords,
                                  stemmed_sdg_keywords = stemmed_sdg_keywords,
                                  DEBUG_MODE = DEBUG_MODE,
                                  .fix_seed = output$random_seed,
                                  .return_output = TRUE)
        testthat::expect_equal(output$mod$theta[,1], new_output$mod$theta[,1])
    }
}
