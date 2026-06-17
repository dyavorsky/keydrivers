# ## Compute usefulness (change in R²)
#
# Calculates importance as the decrease in R² when each predictor is removed.
# Continuous y: lm, R². Binary y: glm(binomial), McFadden pseudo-R².
# Ordinal y: polr, McFadden pseudo-R².
# Ordinal x vars are converted to integer ranks before fitting.
sub_useful <- function(y_var, x_vars, z_vars, data, y_type, params=list(), verbose=FALSE) {

  all_vars      <- c(y_var, x_vars, z_vars)
  complete_data <- data[complete.cases(data[, all_vars]), ]
  n             <- nrow(complete_data)
  n_missing     <- nrow(data) - n

  if (n < length(x_vars) + length(z_vars) + 1)
    stop("Insufficient complete cases for usefulness analysis")

  all_predictors <- c(x_vars, z_vars)

  for (var in all_predictors) {
    if (is.ordered(complete_data[[var]]))
      complete_data[[var]] <- as.numeric(complete_data[[var]])
  }

  full_form <- as.formula(paste(y_var, "~", paste(all_predictors, collapse=" + ")))

  if (y_type == "continuous") {
    full_model <- lm(full_form, data=complete_data)
    r2_full    <- summary(full_model)$r.squared
    get_r2     <- function(form) summary(lm(form, data=complete_data))$r.squared
    model_type <- "lm"
    r2_label   <- "R²"

  } else if (y_type == "binary") {
    full_model <- glm(full_form, family=binomial, data=complete_data)
    r2_full    <- 1 - full_model$deviance / full_model$null.deviance
    get_r2     <- function(form) {
      m <- glm(form, family=binomial, data=complete_data)
      1 - m$deviance / m$null.deviance
    }
    model_type <- "glm(binomial)"
    r2_label   <- "pseudo-R²"

  } else if (y_type == "ordinal") {
    null_form  <- as.formula(paste(y_var, "~ 1"))
    full_model <- polr(full_form, data=complete_data, Hess=TRUE)
    null_model <- polr(null_form, data=complete_data, Hess=TRUE)
    r2_full    <- 1 - full_model$deviance / null_model$deviance
    get_r2     <- function(form) {
      m <- polr(form, data=complete_data, Hess=TRUE)
      1 - m$deviance / null_model$deviance
    }
    model_type <- "polr"
    r2_label   <- "pseudo-R²"

  } else {
    stop("Unknown y_type: ", y_type)
  }

  importance <- setNames(rep(NA_real_, length(x_vars)), x_vars)

  for (x_var in x_vars) {
    reduced_predictors <- setdiff(all_predictors, x_var)
    if (length(reduced_predictors) > 0) {
      reduced_form <- as.formula(paste(y_var, "~", paste(reduced_predictors, collapse=" + ")))
      r2_reduced   <- get_r2(reduced_form)
    } else {
      r2_reduced <- 0
    }
    importance[x_var] <- r2_full - r2_reduced
  }

  if (verbose) {
    miss_str <- if (n_missing > 0) paste0(", ", n_missing, " missing") else ""
    message("\nUsefulness: ", model_type, ", n = ", n, miss_str,
            ", full model ", r2_label, " = ", round(r2_full, 3))
  }

  return(list(
    importance       = importance,
    r2_full          = r2_full,
    n                = n,
    n_missing        = n_missing,
    missing_strategy = "listwise",
    model            = full_model
  ))
}
