args <- tmmv.parse_args_train(slug = "curini")
settings <- tmmv.get_settings(full = TRUE, args = args)

library(here)
library(keyATM)
library(quanteda)
library(purrr)
library(furrr)
library(seededlda)

if (args$debug) {
    settings <- sample(settings, 10)
    cat("DEBUG MODE: Only 10 randomly selected settings will be checked.\n")
    cat("Rerun if you want more checks.\n")
}

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


train_model <- function(setting, args, .fix_seed = NULL, .return_output = FALSE) {
    dfm_filename <- paste0(rlang::hash(setting[1:3]), ".RDS")
    current_dfm <- readRDS(here(args$prefix, args$slug, dfm_filename))

    ## Note that the original does assume the text has been stemmed
    ## I add * to communit, responsabilit, solidariet, libert (so that it will match e.g. comunità)
    ## the original use all singular ("militare" has both singular and plural), except "alleati", "umani", "bombardamenti",
    ## "bombe", "rischi", "vittime"
    ## The singular terms have been added
    ## for adjectives, only the feminine and plural: "umanitaria" and "unmanitari" (reduced to "umanitari*"; so that it can also capture
    ## the musculine form "umanitario")

    updated_dict <- list(multilateralism= c("multilateralism", "comunit*", "responsabilit*", "alleanza", "alleati", "impegno", 
                                            "sicurezza", "coalizione"),
                         humanitarian_dimension= c("democrazia", "umani", "democrazia", "democratica", "diritto", "pace",
                                                   "solidariet*", "libert", "pacific*", 
                                                   "umanitari*", "solidal*"),
                         war= c("guerra", "militare", "bombardamenti", "militari", "costituzione", "disarmo", "chiarezza",
                                "violenza", "bombe", "bomba", "rischi", "rischio", "vittime", "vittima"))
    current <- tmmv.get_current(setting = setting,
                                args = args,
                                keywords = updated_dict,
                                k = c(1, 2, 3),
                                original_iter = c(2000, round(2000 * 0.8), round(2000 * 1.2)),
                                alternative_iter = c(1500, round(1500 * 0.8), round(1500 * 1.2)),
                                .fix_seed = .fix_seed)

    output <- list()
    output$random_seed <- current$random_seed
    output$setting <- setting
    dict <- dictionary(current$keywords)
    
    set.seed(current$random_seed)
    
    key_docs <- keyATM_read(current_dfm)
    key_kw <- read_keywords(dictionary = dict, docs = key_docs)

    available_topics <- check_keywords(key_docs, key_kw)

    if (args$debug) {
        cat("Available topics: ", length(available_topics), "\n")
    }
    
    n_fully_pruned_topics <- length(key_kw) - length(available_topics)
    if (n_fully_pruned_topics > 0) {
        # compensate the fully pruned topics by adding it to the current_k
        current$k <- current$k + n_fully_pruned_topics
        current$keywords <- key_kw[available_topics]
    } else {
        current$keywords <- key_kw
    }    
    if (!setting$alternative_model) {
        output$mod <- textmodel_seededlda(x = current_dfm,
                                          dictionary = dictionary(current$keywords),
                                          valuetype = "fixed",
                                          max_iter = current$iter,
                                          residual = current$k,
                                          verbose = args$debug)
    } else {
        ## key_docs <- keyATM_read(current_dfm)
        ## key_kw <- read_keywords(dictionary = dict, docs = key_docs)
        output$mod <- keyATM(key_docs,
                             no_keyword_topics = current$k,
                             keywords = current$keywords,
                             model = "base",
                             options = list(iterations = current$iter,
                                            verbose = args$debug))
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
    plan(multisession, workers = getOption("tmmv.cores", 1))
}

furrr::future_walk(settings, train_model,
                   args = args,
                   .progress = !args$debug,
                   .options = furrr_options(seed = NULL))

if (args$debug) {
    library(testthat)
    for (setting in settings) {
        current_hash <- rlang::hash(setting)
        testthat::expect_true(file.exists(file.path(args$output_dir, paste0(current_hash, ".RDS"))))
        output <- readRDS(file.path(args$output_dir, paste0(current_hash, ".RDS")))
        if (setting$alternative_model) {
            testthat::expect_true("keyATM_output" %in% class(output$mod))
        } else {
            testthat::expect_true("textmodel_lda" %in% class(output$mod))
            n_theta <- ncol(output$mod$theta)
        }
        expected_k <- c(1, 2, 3)[setting$k_setting] + 3
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
        print("seed:")
        print(output$random_seed)
        new_output <- train_model(setting,
                                  args = args,
                                  .fix_seed = output$random_seed,
                                  .return_output = TRUE)
        testthat::expect_equal(output$mod$theta[,1], new_output$mod$theta[,1])
    }
}
