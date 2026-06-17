# ## Compute SHAP values
#
# Calculates SHAP (Shapley Additive Explanations) values using fastshap::explain.
# Works with all outcome types by fitting appropriate models.
#
# **Parameters:**
# - `y_var`: Name of outcome variable
# - `x_vars`: Names of predictor variables
# - `z_vars`: Names of control variables
# - `data`: Data frame
# - `y_type`: Type of y variable ("continuous", "binary", or "ordinal")
# - `params`: Additional parameters (e.g., `nsim` for number of simulations)
#
# **Returns:** List with importance vector and metadata
sub_shapex <- function(y_var, x_vars, z_vars, data, y_type, params=list()) {

  all_vars <- c(y_var, x_vars, z_vars)
  complete_data <- data[complete.cases(data[, all_vars]), ]
  n <- nrow(complete_data)

  if (n < length(x_vars) + length(z_vars) + 1) {
    stop("Insufficient complete cases for SHAP analysis")
  }

  all_predictors <- c(x_vars, z_vars)
  form <- as.formula(paste(y_var, "~", paste(all_predictors, collapse=" + ")))

  if (y_type == "continuous") {
    model        <- lm(form, data=complete_data)
    pred_wrapper <- function(object, newdata) predict(object, newdata=newdata)

  } else if (y_type == "binary") {
    model        <- glm(form, data=complete_data, family=binomial)
    pred_wrapper <- function(object, newdata) predict(object, newdata=newdata, type="response")

  } else if (y_type == "ordinal") {
    model        <- polr(form, data=complete_data)
    pred_wrapper <- function(object, newdata) as.numeric(predict(object, newdata=newdata))

  } else {
    stop("Unknown y_type: ", y_type)
  }

  tryCatch({
    X    <- complete_data[, all_predictors, drop=FALSE]
    nsim <- if ("nsim" %in% names(params)) params$nsim else 100

    shap_values    <- explain(model, X=X, pred_wrapper=pred_wrapper, nsim=nsim)
    mean_abs_shap  <- colMeans(abs(shap_values))
    importance     <- mean_abs_shap[x_vars]
    names(importance) <- x_vars

    return(list(
      importance       = importance,
      method           = "shap",
      nsim             = nsim,
      n                = n,
      n_missing        = nrow(data) - n,
      missing_strategy = "listwise",
      all_shap         = mean_abs_shap,
      model            = model
    ))

  }, error = function(e) {
    warning("Error computing SHAP values: ", e$message)
    importance <- setNames(rep(NA_real_, length(x_vars)), x_vars)
    return(list(importance=importance, n=n, error=e$message))
  })
}
