args <- tmmv.parse_args_train(slug = "jankin")
settings <- tmmv.get_settings(full = TRUE, args = args)

library(here)
library(keyATM)
library(quanteda)
library(SnowballC)
library(seededlda)
library(furrr)

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

## This is not working because we stemmed first, before doing bigram in jankin01
## sdg_keywords_stemmed <- lapply(sdg_keywords, SnowballC::wordStem)

split_keywords <- lapply(sdg_keywords, strsplit, split = "_")

stemmed_sdg_keywords <- list()

for (i in seq_len(length(split_keywords))) {
    stemmed_sdg_keywords[[i]] <- unique(vapply(lapply(split_keywords[[i]], SnowballC::wordStem),
                                               paste, collapse = "_",
                                               FUN.VALUE = character(1)))
}

names(stemmed_sdg_keywords) <- names(sdg_keywords)

if (args$debug) {
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

train_model <- function(setting, args, sdg_keywords, stemmed_sdg_keywords, .fix_seed = NULL, .return_output = FALSE) {
    dfm_filename <- paste0(rlang::hash(setting[1:3]), ".RDS")
    current_dfm <- readRDS(here(args$prefix, args$slug, dfm_filename))

    current <- tmmv.get_current(setting = setting,
                                args = args,
                                keywords = sdg_keywords,
                                stemmed_keywords = stemmed_sdg_keywords,
                                k = c(1, 3, 5),
                                original_iter = c(1500, round(1500 * 0.8), round(1500 * 1.2)),
                                alternative_iter = c(2000, round(2000 * 0.8), round(2000 * 1.2)),
                                .fix_seed = .fix_seed)
    # find fully pruned topics
    ATM_docs <- keyATM_read(current_dfm)
    available_topics <- check_keywords(ATM_docs, current$keywords)
    if (args$debug) {
        cat("Available topics: ", length(available_topics), "\n")
    }
    n_fully_pruned_topics <- length(current$keywords) - length(available_topics)
    if (n_fully_pruned_topics > 0) {
        # compensate the fully pruned topics by adding it to the current_k
        current$k <- current$k + n_fully_pruned_topics
        current$keywords <- current$keywords[available_topics]
    }

    output <- list()
    output$random_seed <- current$random_seed
    output$setting <- setting

    set.seed(current$random_seed)

    if (!setting$alternative_model) {
        output$mod <- keyATM(docs = ATM_docs,
                      no_keyword_topics = current$k,
                      keywords = current$keywords,
                      model = "base",
                      options = list(iterations = current$iter,
                                     prune = TRUE,
                                     verbose = args$debug))
    } else {
        output$mod <- textmodel_seededlda(x = current_dfm,
                                          dictionary = quanteda::dictionary(current$keywords),
                                          valuetype = "fixed",
                                          max_iter = current$iter,
                                          residual = current$k,
                                          verbose = args$debug)
    }
    if (.return_output) {
        return(output)
    }
    current_hash <- rlang::hash(setting)
    saveRDS(output, file.path(args$output_dir, paste0(current_hash, ".RDS")))
}

if (args$debug) {
    plan(sequential)
} else {
    plan(multisession, workers = getOption("tmmv.jankin.workers", 1))
}

furrr::future_walk(settings, train_model,
                   args = args,
                   sdg_keywords = sdg_keywords,
                   stemmed_sdg_keywords = stemmed_sdg_keywords,
                   .progress = !args$debug)

if (args$debug) {
    library(testthat)
    for (setting in settings) {
        current_hash <- rlang::hash(setting)
        testthat::expect_true(file.exists(file.path(args$output_dir, paste0(current_hash, ".RDS"))))
        output <- readRDS(file.path(args$output_dir, paste0(current_hash, ".RDS")))
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
        testthat::expect_true(file.exists(file.path(args$output_dir, paste0(current_hash, ".RDS"))))
        output <- readRDS(file.path(args$output_dir, paste0(current_hash, ".RDS")))
        new_output <- train_model(setting,
                                  args = args,
                                  sdg_keywords = sdg_keywords,
                                  stemmed_sdg_keywords = stemmed_sdg_keywords,
                                  .fix_seed = output$random_seed,
                                  .return_output = TRUE)
        testthat::expect_equal(output$mod$theta[,1], new_output$mod$theta[,1])
    }
}
