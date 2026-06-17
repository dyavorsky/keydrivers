print.kda <- function(x, digits=3, ...) {
  cat("Key Drivers Analysis\n")
  cat(strrep("-", 50), "\n")
  cat("Formula: ", deparse(x$formula), "\n", sep="")
  cat("Outcome: ", x$y_var, " (", x$y_type, ")\n", sep="")
  cat("Drivers: ", paste(paste0(x$x_vars, " (", x$x_types, ")"), collapse=", "), "\n", sep="")
  if (length(x$z_vars) > 0)
    cat("Controls:", paste(x$z_vars, collapse=", "), "\n")

  cat("\nImportance:\n")
  print(round(x$importance, digits))

  method_meta <- list(
    correlations = x$correlations,
    betas        = x$betas,
    usefulness   = x$usefulness,
    jrw          = x$jrw,
    shapley      = x$shapley,
    shapex       = x$shapex,
    randomforest = x$randomforest,
    xgboost      = x$xgboost
  )
  method_meta <- Filter(Negate(is.null), method_meta)

  if (length(method_meta) > 0) {
    cat("\nMethod details:\n")
    for (nm in names(method_meta)) {
      m <- method_meta[[nm]]
      label <- switch(nm,
        correlations = "Correlations",
        betas        = "Standardized Betas",
        usefulness   = "Usefulness",
        jrw          = "Johnson Relative Weights",
        shapley      = "Shapley/LMG",
        shapex       = "SHAP",
        randomforest = "Random Forest",
        xgboost      = "XGBoost"
      )
      parts <- character(0)
      if (!is.null(m$model_type))       parts <- c(parts, m$model_type)
      if (!is.null(m$n))                parts <- c(parts, paste0("n = ", m$n))
      if (!is.null(m$n_missing) && m$n_missing > 0)
                                        parts <- c(parts, paste0(m$n_missing, " missing"))
      if (!is.null(m$r2)    && !is.na(m$r2))    parts <- c(parts, paste0("R² = ",   round(m$r2, digits)))
      if (!is.null(m$r2_full) && !is.na(m$r2_full)) parts <- c(parts, paste0("R² = ", round(m$r2_full, digits)))
      if (!is.null(m$nsim))             parts <- c(parts, paste0("nsim = ", m$nsim))
      if (!is.null(m$ntree))            parts <- c(parts, paste0("ntree = ", m$ntree))
      if (!is.null(m$nrounds))          parts <- c(parts, paste0("nrounds = ", m$nrounds))
      if (!is.null(m$objective))        parts <- c(parts, m$objective)
      cat("  ", label, ": ", paste(parts, collapse=", "), "\n", sep="")
    }
  }

  invisible(x)
}
