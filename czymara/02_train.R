args <- tmmv.parse_args_train(slug = "czymara")
settings <- tmmv.get_settings(full = TRUE, args = args)

library(here)
library(keyATM)
library(quanteda)
library(purrr)
library(stm)

if (args$debug) {
    settings <- sample(settings, 10)
    cat("DEBUG MODE: Only 10 randomly selected settings will be checked.\n")
    cat("Rerun if you want more checks.\n")
}

train_model <- function(
    setting,
    args,
    .fix_seed = NULL,
    .return_output = FALSE
) {
    dfm_filename <- paste0(rlang::hash(setting[1:3]), ".RDS")
    current_dfm <- readRDS(here(args$prefix, args$slug, dfm_filename))

    current <- tmmv.get_current(
        setting = setting,
        args = args,
        k = tmmv.data[[args$slug]]$k,
        original_iter = c(500, round(500 * 0.8), round(500 * 1.2)),
        alternative_iter = c(2000, round(2000 * 0.8), round(2000 * 1.2)),
        .fix_seed = .fix_seed
    )

    output <- list()
    output$random_seed <- current$random_seed
    output$setting <- setting

    ## STM drops rows silently, we do it here explicitly
    rowsum_priv <- apply(current_dfm, 1, sum)
    trimmed_dfm <- current_dfm[rowsum_priv != 0, ]

    set.seed(current$random_seed)

    if (!setting$alternative_model) {
        output$mod <- stm(
            trimmed_dfm,
            K = current$k,
            init.type = "Spectral",
            max.em.its = current$iter,
            prevalence = ~gender,
            verbose = args$debug,
            data = trimmed_dfm@docvars
        )
    } else {
        keyATM_docs <- keyATM_read(texts = trimmed_dfm)

        output$mod <- weightedLDA(
            docs = keyATM_docs,
            number_of_topics = current$k,
            model = "covariates",
            model_settings = list(
                covariates_data = trimmed_dfm@docvars,
                covariates_formula = ~gender
            ),
            options = list(
                iterations = current$iter,
                verbose = args$debug
            )
        )
    }
    output$theta <- tmmv.unify_theta(output$mod, trimmed_dfm, current_dfm)
    output$docvars <- trimmed_dfm@docvars
    if (.return_output) {
        return(output)
    }
    current_hash <- rlang::hash(setting)
    saveRDS(output, file.path(args$output_dir, paste0(current_hash, ".RDS")))
}

purrr::walk(settings, train_model, args = args, .progress = !args$debug)

if (args$debug) {
    library(testthat)
    for (setting in settings) {
        current_hash <- rlang::hash(setting)
        testthat::expect_true(file.exists(file.path(
            args$output_dir,
            paste0(current_hash, ".RDS")
        )))
        output <- readRDS(file.path(
            args$output_dir,
            paste0(current_hash, ".RDS")
        ))
        if (setting$alternative_model) {
            testthat::expect_true("keyATM_output" %in% class(output$mod))
        } else {
            testthat::expect_true("STM" %in% class(output$mod))
        }

        expected_k <- tmmv.data[[args$slug]]$k[setting$k_setting]
        expect_equal(expected_k, ncol(output$theta))
        ## can't test iter
        ## output$theta
        dfm_filename <- paste0(rlang::hash(setting[1:3]), ".RDS")
        current_dfm <- readRDS(here(args$prefix, args$slug, dfm_filename))
        expect_equal(ndoc(current_dfm), nrow(output$theta))
        expect_equal(ndoc(current_dfm), nrow(output$theta))
        expect_equal(expected_k, ncol(output$theta))
        cat("Reproducibility check \n")
        repro_settings <- sample(settings, 2)
        for (setting in repro_settings) {
            current_hash <- rlang::hash(setting)
            testthat::expect_true(file.exists(file.path(
                args$output_dir,
                paste0(current_hash, ".RDS")
            )))
            output <- readRDS(file.path(
                args$output_dir,
                paste0(current_hash, ".RDS")
            ))
            print("seed:")
            print(output$random_seed)
            new_output <- train_model(
                setting,
                args = args,
                .fix_seed = output$random_seed,
                .return_output = TRUE
            )
            testthat::expect_equal(
                output$mod$theta[, 1],
                new_output$mod$theta[, 1]
            )
        }
    }
}

## theta <- mod$theta
## rownames(theta) <- docnames(trimmed_dfm)

## excluded_docs <- setdiff(docnames(current_dfm), docnames(trimmed_dfm))

## fake_theta <- matrix(rep(1/k, length(excluded_docs) * k), nrow = length(excluded_docs), ncol = k)

## rownames(fake_theta) <- excluded_docs

## final_theta <- rbind(theta, fake_theta)

## final_theta <- final_theta[match(rownames(current_dfm),rownames(final_theta)) ,]

## sanity check
## all(rownames(unify_theta(mod, trimmed_dfm, current_dfm)) == rownames(current_dfm))
## all(final_theta["text474",] == theta["text474",])

## est <- estimateEffect(1:8 ~ gender, mod,
##                       meta = trimmed_dfm@docvars, uncertainty = "Global")

## topic_prob_gender <- summary(mod)

## plot(est, covariate = "gender",
##      model = mod, method = "difference",
##      cov.value1 = "male", cov.value2 = "female"
##      )

## effects <- sapply(1:8, function(x) est$parameters[[x]][[x]]$est[2])
## se <- sapply(1:8, function(x) sqrt(est$parameters[[x]][[x]]$vcov[2,2]))

## effecttable <- as.data.frame(cbind(effects, se))

## effecttable$CIupper <- effecttable$effects + 1.96*effecttable$se
## effecttable$CIlower <- effecttable$effects - 1.96*effecttable$se

## ## this reverse the prob
## effecttable <- effecttable*-1
## effecttable %<>%
##   mutate(sig = if_else(CIupper<0 & CIlower<0 |
##                          CIupper>0 & CIlower>0,
##                        1, 0))

## effecttable$labels <- with(gamma_terms, reorder(topic, gamma))[1:8]

### keyATM
