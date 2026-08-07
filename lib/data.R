tmmv.s3model <- list()
tmmv.s3model[["Seeded LDA"]] <- "textmodel_lda"
tmmv.s3model[["STM"]] <- "STM"
tmmv.s3model[["keyATM"]] <- "keyATM_output"
tmmv.s3model[["Weighted LDA"]] <- "keyATM_output"

tmmv.data <- list()

tmmv.data$chan <- list()
tmmv.data$chan$original_model <- "keyATM"
tmmv.data$chan$alternative_model <- "Seeded LDA"
tmmv.data$chan$keyword <- TRUE
## excl. keyworded topics, dictionary below
tmmv.data$chan$k <- c(39, 35, 43)

## follow the "setting" schema from tmmv.get_settings()
tmmv.data$chan$anchor <- list()
tmmv.data$chan$anchor$token_normalization <- "stemming"
tmmv.data$chan$anchor$stopword_removal <- TRUE
tmmv.data$chan$anchor$trimming <- TRUE
tmmv.data$chan$anchor$alternative_model <- FALSE
tmmv.data$chan$anchor$k_setting <- 1
tmmv.data$chan$anchor$iteration_setting <- 1

tmmv.data$curini <- list()
tmmv.data$curini$original_model <- "Seeded LDA"
tmmv.data$curini$alternative_model <- "keyATM"
tmmv.data$curini$keyword <- TRUE
tmmv.data$curini$k <- c(1, 2, 3)

tmmv.data$curini$anchor <- list()
tmmv.data$curini$anchor$token_normalization <- "stemming"
tmmv.data$curini$anchor$stopword_removal <- TRUE
tmmv.data$curini$anchor$trimming <- FALSE
tmmv.data$curini$anchor$alternative_model <- FALSE
tmmv.data$curini$anchor$k_setting <- 1
tmmv.data$curini$anchor$iteration_setting <- 1

tmmv.data$czymara <- list()
tmmv.data$czymara$original_model <- "STM"
tmmv.data$czymara$alternative_model <- "Weighted LDA"
tmmv.data$czymara$keyword <- FALSE
tmmv.data$czymara$k <- c(8, 6, 10)

tmmv.data$czymara$anchor <- list()
tmmv.data$czymara$anchor$token_normalization <- "stemming"
tmmv.data$czymara$anchor$stopword_removal <- TRUE
tmmv.data$czymara$anchor$trimming <- TRUE
tmmv.data$czymara$anchor$alternative_model <- FALSE
tmmv.data$czymara$anchor$k_setting <- 1
tmmv.data$czymara$anchor$iteration_setting <- 1

tmmv.data$jankin <- list()
tmmv.data$jankin$original_model <- "keyATM"
tmmv.data$jankin$alternative_model <- "Seeded LDA"
tmmv.data$jankin$keyword <- TRUE
tmmv.data$jankin$k <- c(1, 3, 5)

tmmv.data$jankin$anchor <- list()
tmmv.data$jankin$anchor$token_normalization <- "none"
tmmv.data$jankin$anchor$stopword_removal <- TRUE
tmmv.data$jankin$anchor$trimming <- FALSE
tmmv.data$jankin$anchor$alternative_model <- FALSE
tmmv.data$jankin$anchor$k_setting <- 1
tmmv.data$jankin$anchor$iteration_setting <- 1

tmmv.data$takano <- list()
tmmv.data$takano$original_model <- "STM"
tmmv.data$takano$alternative_model <- "Weighted LDA"
tmmv.data$takano$keyword <- FALSE
tmmv.data$takano$k <- c(7, 6, 8)

tmmv.data$takano$anchor <- list()
tmmv.data$takano$anchor$token_normalization <- "lemmatization"
tmmv.data$takano$anchor$stopword_removal <- TRUE
tmmv.data$takano$anchor$trimming <- TRUE
tmmv.data$takano$anchor$alternative_model <- FALSE
tmmv.data$takano$anchor$k_setting <- 1
tmmv.data$takano$anchor$iteration_setting <- 1

tmmv.data$tvinnereim <- list()
tmmv.data$tvinnereim$original_model <- "STM"
tmmv.data$tvinnereim$alternative_model <- "Weighted LDA"
tmmv.data$tvinnereim$keyword <- FALSE
tmmv.data$tvinnereim$k <- c(4, 3, 5)

tmmv.data$tvinnereim$anchor <- list()
tmmv.data$tvinnereim$anchor$token_normalization <- "stemming"
tmmv.data$tvinnereim$anchor$stopword_removal <- TRUE
tmmv.data$tvinnereim$anchor$trimming <- TRUE
tmmv.data$tvinnereim$anchor$alternative_model <- FALSE
tmmv.data$tvinnereim$anchor$k_setting <- 1
tmmv.data$tvinnereim$anchor$iteration_setting <- 1

tmmv.data$chan$dict <- list(
    socialmedia = c(
        "facebook",
        "twitter",
        "blog*",
        "sns*",
        "tweet*",
        "blog*"
    )
)

## Note that the original does assume the text has been stemmed using an English stemmer.
## We produce this by referring to the original terms (Table 2 of the original paper), stem them using an Italian stemmer,
## and then add * to all stemmed terms.
tmmv.data$curini$dict <- list(
    multilateralism = c(
        "multilateral*",
        "comun*",
        "respons*",
        "alleanz*",
        "alle*",
        "impegn*",
        "sicurezz*",
        "coalizion*"
    ),
    humanitarian_dimension = c(
        "democraz*",
        "democrat*",
        "uman*",
        "diritt*",
        "pac*",
        "solidariet*",
        "libert*",
        "pacif*",
        "umanitar*",
        "solidal*"
    ),
    war = c(
        "guerr*",
        "milit*",
        "bombard*",
        "militar*",
        "costitu*",
        "disarm*",
        "chiarezz*",
        "violenz*",
        "bomb*",
        "risc*",
        "vittim*"
    )
)

tmmv.data$jankin$dict <- list(
    SDG1 = c(
        "poverty",
        "extreme_poverty",
        "poor",
        "socioeconomic",
        "income",
        "living_standards",
        "living_standard"
    ),
    SDG2 = c(
        "hunger",
        "food_security",
        "nutrition",
        "agriculture",
        "farming",
        "malnutrition",
        "sustainable_agriculture",
        "food_systems",
        "food_system"
    ),
    SDG3 = c(
        "health",
        "wellbeing",
        "disease",
        "maternal_health",
        "child_mortality",
        "epidemic",
        "vaccines",
        "healthcare"
    ),
    SDG4 = c(
        "education",
        "literacy",
        "school",
        "primary_education",
        "secondary_education",
        "tertiary_education",
        "lifelong_learning",
        "skills_development"
    ),
    SDG5 = c(
        "gender_equality",
        "women",
        "girls",
        "empowerment",
        "discrimination",
        "female",
        "gender_mainstreaming",
        "gender_based",
        "gender_violence"
    ),
    SDG6 = c(
        "water",
        "sanitation",
        "clean_water",
        "drinking_water",
        "waste_water",
        "wastewater",
        "water_resources",
        "water_management",
        "hygiene"
    ),
    SDG7 = c(
        "energy",
        "renewable_energy",
        "clean_energy",
        "sustainable_energy",
        "electricity",
        "energy_access",
        "energy_efficiency",
        "energy_security"
    ),
    SDG8 = c(
        "economic_growth",
        "employment",
        "decent_work",
        "labour",
        "inclusive_growth",
        "sustainable_growth",
        "labour_market",
        "youth_employment"
    ),
    SDG9 = c(
        "infrastructure",
        "innovation",
        "industrialization",
        "technology",
        "research",
        "development",
        "sustainable_industrialization",
        "sustainable_industry",
        "technological_progress"
    ),
    SDG10 = c(
        "inequality",
        "inequalities",
        "income_inequality",
        "wealth_distribution",
        "social_inclusion",
        "equal_opportunity",
        "equal_opportunities",
        "discrimination",
        "economic_divide",
        "equity"
    ),
    SDG11 = c(
        "cities",
        "urban",
        "sustainable_cities",
        "urban_planning",
        "urban_development",
        "urbanisation",
        "urban_infrastructure",
        "housing"
    ),
    SDG12 = c(
        "sustainable_consumption",
        "sustainable_production",
        "resource_efficiency",
        "waste_management",
        "recycling",
        "supply_chain",
        "circular_economy",
        "responsible_consumption"
    ),
    SDG13 = c(
        "climate_change",
        "global_warming",
        "greenhouse_gas",
        "emissions",
        "carbon_dioxide",
        "climate_action",
        "climate_resilience",
        "climate_mitigation"
    ),
    SDG14 = c(
        "oceans",
        "marine",
        "coastal",
        "sea",
        "seas",
        "marine_resources",
        "fisheries",
        "aquaculture",
        "marine_pollution"
    ),
    SDG15 = c(
        "biodiversity",
        "ecosystems",
        "ecosystem",
        "land",
        "forest",
        "forests",
        "wildlife",
        "habitat",
        "deforestation",
        "desertification",
        "species"
    ),
    SDG16 = c(
        "peace",
        "justice",
        "institutions",
        "rule_law",
        "governance",
        "accountability",
        "transparency",
        "corruption",
        "human_rights",
        "violence"
    ),
    SDG17 = c(
        "partnership",
        "international_cooperation",
        "global_partnership",
        "development_goals",
        "development_cooperation",
        "financing_development",
        "development_finance",
        "trade",
        "technology_transfer",
        "capacity_building"
    )
)
