# ## Compute Johnson Relative Weights
#
# Calculates Johnson Relative Weights using iopsych::relWt.
# Applicable to continuous and binary outcomes (ordinal y returns NAs).
# Ordinal x vars are converted to integer ranks before matrix construction
# to avoid as.matrix() coercing ordered factors to a character matrix.
sub_jrw <- function(y_var, x_vars, z_vars, data, y_type, params=list(), verbose=FALSE) {

  all_vars      <- c(y_var, x_vars, z_vars)
  complete_data <- data[complete.cases(data[, all_vars]), ]
  n             <- nrow(complete_data)
  n_missing     <- nrow(data) - n

  if (n < length(x_vars) + length(z_vars) + 1)
    stop("Insufficient complete cases for JRW analysis")

  if (!y_type %in% c("continuous", "binary")) {
    warning("Johnson Relative Weights only applicable to continuous and binary outcomes. Returning NAs.")
    importance <- setNames(rep(NA_real_, length(x_vars)), x_vars)
    return(list(importance=importance, r2=NA, n=n,
                message="Not applicable for ordinal outcomes"))
  }

  all_predictors <- c(x_vars, z_vars)

  for (var in all_predictors) {
    if (is.ordered(complete_data[[var]]))
      complete_data[[var]] <- as.numeric(complete_data[[var]])
  }

  X <- as.matrix(complete_data[, all_predictors])
  y <- complete_data[[y_var]]

  tryCatch({
    rw_result  <- relWt(X, y)
    importance <- rw_result$relWt[x_vars]
    names(importance) <- x_vars

    if (verbose) {
      miss_str <- if (n_missing > 0) paste0(", ", n_missing, " missing") else ""
      message("\nJohnson Relative Weights: n = ", n, miss_str,
              ", R² = ", round(rw_result$R2, 3))
    }

    return(list(
      importance       = importance,
      r2               = rw_result$R2,
      n                = n,
      n_missing        = n_missing,
      missing_strategy = "listwise",
      all_rel_weights  = rw_result$relWt
    ))

  }, error = function(e) {
    warning("Error computing Johnson Relative Weights: ", e$message)
    importance <- setNames(rep(NA_real_, length(x_vars)), x_vars)
    return(list(importance=importance, r2=NA, n=n, error=e$message))
  })
}
