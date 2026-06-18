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

  cor_vars <- c(y_var, all_predictors)
  R        <- cor(complete_data[, cor_vars], use = "everything")
  x_col    <- seq(2, length(cor_vars))

  tryCatch({
    rw_result  <- relWt(R, y_col = 1, x_col = x_col)
    eps_vec    <- as.numeric(rw_result$eps[["EPS"]])  # $eps is a data.frame
    all_eps    <- setNames(eps_vec, all_predictors)
    importance <- all_eps[x_vars]
    r2         <- sum(eps_vec)                         # weights sum to full-model R²

    if (verbose) {
      miss_str <- if (n_missing > 0) paste0(", ", n_missing, " missing") else ""
      message("\nJohnson Relative Weights: n = ", n, miss_str,
              ", R² = ", round(r2, 3))
    }

    return(list(
      importance       = importance,
      r2               = r2,
      n                = n,
      n_missing        = n_missing,
      missing_strategy = "listwise",
      all_rel_weights  = all_eps
    ))

  }, error = function(e) {
    warning("Error computing Johnson Relative Weights: ", e$message)
    importance <- setNames(rep(NA_real_, length(x_vars)), x_vars)
    return(list(importance=importance, r2=NA, n=n, error=e$message))
  })
}
