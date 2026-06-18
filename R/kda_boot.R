# ## Bootstrap Confidence Intervals for Key Drivers Analysis
#
# Runs kda() on B bootstrap resamples and returns percentile CIs for every
# (variable, method) cell in the importance matrix.
#
# ### Parameters
# - `form`: Formula passed directly to kda()
# - `data`: Data frame passed directly to kda()
# - `B`: Number of bootstrap resamples (default 200)
# - `conf_level`: Confidence level, e.g. 0.95 (default)
# - `seed`: Optional integer seed for reproducibility
# - `...`: All other arguments passed to kda() (method flags, _params, etc.)
#
# ### Notes
# For stochastic methods (randforest, xgboost_, shapex), reduce per-iteration
# cost via rf_params = list(ntree = 100), xgb_params = list(nrounds = 50), or
# shapex_params = list(nsim = 50) when B is large.
#
# ### Returns
# List of class "kda_boot" with:
# - `estimate`: kda object from the full data
# - `ci_lower`: matrix of lower CI bounds (same shape as estimate$importance)
# - `ci_upper`: matrix of upper CI bounds
# - `B`: number of successful iterations
# - `B_requested`: B argument as supplied
# - `conf_level`: confidence level used
kda_boot <- function(form, data, B = 200, conf_level = 0.95, seed = NULL, ...) {

  if (!is.null(seed)) set.seed(seed)

  estimate <- kda(form, data, ..., verbose = FALSE)

  n_rows <- nrow(data)
  alpha  <- (1 - conf_level) / 2

  boot_list <- vector("list", B)
  for (b in seq_len(B)) {
    idx       <- sample(n_rows, n_rows, replace = TRUE)
    boot_data <- data[idx, , drop = FALSE]
    tryCatch({
      boot_result    <- kda(form, boot_data, ..., verbose = FALSE)
      boot_list[[b]] <- boot_result$importance
    }, error = function(e) NULL)
  }

  boot_list <- Filter(Negate(is.null), boot_list)
  B_actual  <- length(boot_list)

  if (B_actual == 0)
    stop("All ", B, " bootstrap iterations failed.")

  if (B_actual < B)
    warning(B - B_actual, " of ", B, " bootstrap iterations failed and were dropped.")

  nr  <- nrow(boot_list[[1]])
  nc  <- ncol(boot_list[[1]])
  dn  <- dimnames(boot_list[[1]])
  arr <- array(unlist(boot_list), dim = c(nr, nc, B_actual),
               dimnames = list(dn[[1]], dn[[2]], NULL))

  ci_lower <- apply(arr, c(1L, 2L), quantile, probs = alpha,       na.rm = TRUE)
  ci_upper <- apply(arr, c(1L, 2L), quantile, probs = 1 - alpha,   na.rm = TRUE)

  structure(
    list(
      estimate    = estimate,
      ci_lower    = ci_lower,
      ci_upper    = ci_upper,
      B           = B_actual,
      B_requested = B,
      conf_level  = conf_level
    ),
    class = "kda_boot"
  )
}


print.kda_boot <- function(x, digits = 2, ...) {
  est   <- x$estimate
  pct   <- round(x$conf_level * 100)
  B_str <- if (x$B < x$B_requested)
              paste0("B = ", x$B, " of ", x$B_requested, " succeeded")
            else
              paste0("B = ", x$B)

  cat("Key Drivers Analysis (Bootstrap CIs, ", B_str, ", ", pct, "% CI)\n", sep = "")
  cat(strrep("-", 50), "\n")
  cat("Formula: ",  deparse(est$formula), "\n", sep = "")
  cat("Outcome: ",  est$y_var, " (", est$y_type, ")\n", sep = "")
  cat("Drivers: ",  paste(paste0(est$x_vars, " (", est$x_types, ")"), collapse = ", "), "\n", sep = "")
  if (length(est$z_vars) > 0)
    cat("Controls:", paste(est$z_vars, collapse = ", "), "\n")

  cat("\nPoint Estimates:\n")
  print(round(est$importance, digits))

  alpha_lo <- round((1 - x$conf_level) / 2 * 100, 1)
  alpha_hi <- 100 - alpha_lo
  cat("\n", pct, "% Confidence Intervals — Lower (", alpha_lo, "%):\n", sep = "")
  print(round(x$ci_lower, digits))
  cat("\n", pct, "% Confidence Intervals — Upper (", alpha_hi, "%):\n", sep = ""  )
  print(round(x$ci_upper, digits))

  invisible(x)
}
