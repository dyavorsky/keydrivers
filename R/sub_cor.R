# ## Compute bivariate correlations
#
# Calculates correlations between outcome and each predictor, selecting the
# appropriate method based on variable types:
#   - continuous/binary + continuous/binary: Pearson
#   - any ordinal pairing: polyserial or polychoric via hetcor()
#
# Missing values are handled pairwise: each y-x pair is filtered to complete
# cases independently before computing its correlation.
sub_cor <- function(y_var, x_vars, data, params=list(), verbose=FALSE) {

  importance  <- setNames(rep(NA_real_,      length(x_vars)), x_vars)
  cor_methods <- setNames(rep(NA_character_, length(x_vars)), x_vars)
  n_obs       <- setNames(rep(NA_integer_,   length(x_vars)), x_vars)
  n_total     <- nrow(data)

  y_type <- detect_var_type(data[[y_var]])

  if (verbose) message("\nCorrelations (pairwise deletion):")

  for (x_var in x_vars) {
    x_type <- detect_var_type(data[[x_var]])

    complete_idx <- complete.cases(data[[y_var]], data[[x_var]])
    y_vec        <- data[[y_var]][complete_idx]
    x_vec        <- data[[x_var]][complete_idx]
    n_obs[x_var] <- sum(complete_idx)
    n_miss       <- n_total - n_obs[x_var]

    if (y_type %in% c("continuous", "binary") && x_type %in% c("continuous", "binary")) {
      importance[x_var]  <- abs(cor(y_vec, x_vec, method="pearson"))
      cor_methods[x_var] <- "pearson"
    } else {
      het_result         <- hetcor(y_vec, x_vec, std.err=FALSE)
      importance[x_var]  <- abs(het_result$correlations[1, 2])
      cor_methods[x_var] <- het_result$type[1, 2]
    }

    if (verbose) {
      miss_str <- if (n_miss > 0) paste0(", ", n_miss, " missing") else ""
      message("  ", x_var, ": ", cor_methods[x_var], " (n = ", n_obs[x_var], miss_str, ")")
    }
  }

  return(list(
    importance       = importance,
    cor_methods      = cor_methods,
    n_obs            = n_obs,
    missing_strategy = "pairwise"
  ))
}
