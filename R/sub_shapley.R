# ## Compute Shapley/LMG importance values
#
# Delegates to the shapley package. Ordinal x vars are converted to integer
# ranks before the call; missing values are handled via listwise deletion.
sub_shapley <- function(y_var, x_vars, z_vars, data, y_type, params=list(), verbose=FALSE) {

  all_vars      <- c(y_var, x_vars, z_vars)
  complete_data <- data[complete.cases(data[, all_vars]), ]
  n             <- nrow(complete_data)
  n_missing     <- nrow(data) - n

  if (n < length(x_vars) + length(z_vars) + 1)
    stop("Insufficient complete cases for Shapley analysis")

  for (var in c(x_vars, z_vars)) {
    if (is.ordered(complete_data[[var]]))
      complete_data[[var]] <- as.numeric(complete_data[[var]])
  }

  tryCatch({
    result     <- shapley::shapley(y_var, x_vars, z_vars, complete_data, y_type)
    importance <- result$values
    r2_full    <- result$r2
    model_type <- result$model_type

    if (verbose) {
      miss_str <- if (n_missing > 0) paste0(", ", n_missing, " missing") else ""
      r2_label <- if (y_type == "continuous") "R²" else "pseudo-R²"
      message("\nShapley/LMG: ", model_type, ", n = ", n, miss_str,
              ", full model ", r2_label, " = ", round(r2_full, 3))
    }

    return(list(
      importance       = importance,
      model_type       = model_type,
      method           = "lmg",
      r2               = r2_full,
      n                = n,
      n_missing        = n_missing,
      missing_strategy = "listwise"
    ))

  }, error = function(e) {
    warning("Error computing Shapley values: ", e$message)
    importance <- setNames(rep(NA_real_, length(x_vars)), x_vars)
    return(list(importance=importance, r2=NA, n=n, error=e$message))
  })
}
