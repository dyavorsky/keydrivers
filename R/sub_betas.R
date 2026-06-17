# ## Compute standardized regression coefficients
#
# Fits regression model with scaled predictors, selecting model type based on
# outcome variable type (lm, glm binomial, polr).
#
# Ordinal predictors are converted to integer ranks before scaling so that a
# single standardized coefficient is produced per variable.
sub_betas <- function(y_var, x_vars, z_vars, data, y_type, params=list(), verbose=FALSE) {

  all_vars      <- c(y_var, x_vars, z_vars)
  complete_data <- data[complete.cases(data[, all_vars]), ]
  n             <- nrow(complete_data)
  n_missing     <- nrow(data) - n

  if (n < length(x_vars) + length(z_vars) + 1)
    stop("Insufficient complete cases for regression")

  # Scale predictors: convert ordinal to integer ranks first, then scale all numeric
  scaled_data <- complete_data
  for (var in c(x_vars, z_vars)) {
    if (is.ordered(complete_data[[var]])) {
      scaled_data[[var]] <- scale(as.numeric(complete_data[[var]]))[, 1]
    } else if (is.numeric(complete_data[[var]])) {
      scaled_data[[var]] <- scale(complete_data[[var]])[, 1]
    }
  }

  all_predictors <- c(x_vars, z_vars)
  form <- as.formula(paste(y_var, "~", paste(all_predictors, collapse=" + ")))

  if (y_type == "continuous") {
    model      <- lm(form, data=scaled_data)
    coeffs     <- coef(model)
    r2         <- summary(model)$r.squared
    model_type <- "lm"

  } else if (y_type == "binary") {
    model      <- glm(form, data=scaled_data, family=binomial)
    coeffs     <- coef(model)
    r2         <- 1 - (model$deviance / model$null.deviance)
    model_type <- "glm_binomial"

  } else if (y_type == "ordinal") {
    model      <- polr(form, data=scaled_data, Hess=TRUE)
    coeffs     <- coef(model)
    null_model <- polr(as.formula(paste(y_var, "~ 1")), data=scaled_data)
    r2         <- 1 - (model$deviance / null_model$deviance)
    model_type <- "polr"

  } else {
    stop("Unknown y_type: ", y_type)
  }

  importance <- abs(coeffs[x_vars])
  names(importance) <- x_vars

  if (verbose) {
    miss_str <- if (n_missing > 0) paste0(", ", n_missing, " missing") else ""
    message("\nStandardized Betas: ", model_type,
            " (n = ", n, miss_str, ", R² = ", round(r2, 3), ")")
  }

  return(list(
    importance       = importance,
    model_type       = model_type,
    r2               = r2,
    n                = n,
    n_missing        = n_missing,
    missing_strategy = "listwise",
    model            = model
  ))
}
