# ## Compute Random Forest importance
#
# Fits Random Forest model and extracts variable importance scores.
# Continuous y: regression forest, %IncMSE importance.
# Binary/ordinal y: classification forest, MeanDecreaseAccuracy importance.
sub_randomforest <- function(y_var, x_vars, z_vars, data, y_type, params=list(), verbose=FALSE) {

  all_vars      <- c(y_var, x_vars, z_vars)
  complete_data <- data[complete.cases(data[, all_vars]), ]
  n             <- nrow(complete_data)
  n_missing     <- nrow(data) - n

  if (n < length(x_vars) + length(z_vars) + 1)
    stop("Insufficient complete cases for Random Forest analysis")

  all_predictors <- c(x_vars, z_vars)
  form  <- as.formula(paste(y_var, "~", paste(all_predictors, collapse=" + ")))
  ntree <- if ("ntree" %in% names(params)) params$ntree else 500
  mtry  <- if ("mtry"  %in% names(params)) params$mtry  else max(floor(length(all_predictors)/3), 1)

  if (y_type %in% c("ordinal", "binary"))
    complete_data[[y_var]] <- as.factor(complete_data[[y_var]])

  tryCatch({
    rf_model   <- randomForest(form, data=complete_data, ntree=ntree, mtry=mtry, importance=TRUE)
    imp_matrix <- importance(rf_model)

    if (y_type == "continuous") {
      imp_scores <- if ("%IncMSE" %in% colnames(imp_matrix)) imp_matrix[, "%IncMSE"] else imp_matrix[, 1]
      perf_metric <- mean(rf_model$rsq)
      perf_name   <- "mean_rsq"
    } else {
      imp_scores  <- if ("MeanDecreaseAccuracy" %in% colnames(imp_matrix)) imp_matrix[, "MeanDecreaseAccuracy"] else imp_matrix[, 1]
      perf_metric <- 1 - mean(rf_model$err.rate[, "OOB"])
      perf_name   <- "oob_accuracy"
    }

    importance_vals <- imp_scores[x_vars]
    names(importance_vals) <- x_vars

    if (verbose) {
      miss_str <- if (n_missing > 0) paste0(", ", n_missing, " missing") else ""
      message("\nRandom Forest: n = ", n, miss_str,
              ", ntree = ", ntree, ", mtry = ", mtry,
              ", ", perf_name, " = ", round(perf_metric, 3))
    }

    return(list(
      importance       = importance_vals,
      ntree            = ntree,
      mtry             = mtry,
      performance      = perf_metric,
      performance_name = perf_name,
      n                = n,
      n_missing        = n_missing,
      missing_strategy = "listwise",
      model            = rf_model
    ))

  }, error = function(e) {
    warning("Error computing Random Forest importance: ", e$message)
    importance_vals <- setNames(rep(NA_real_, length(x_vars)), x_vars)
    return(list(importance=importance_vals, n=n, error=e$message))
  })
}
