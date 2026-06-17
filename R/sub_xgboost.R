# ## Compute XGBoost importance
#
# Fits XGBoost model and extracts gain-based variable importance.
# Continuous y: reg:squarederror. Binary y: binary:logistic.
# Ordinal y: binary:logistic (2 levels) or multi:softmax (3+ levels).
sub_xgboost <- function(y_var, x_vars, z_vars, data, y_type, params=list(), verbose=FALSE) {

  all_vars      <- c(y_var, x_vars, z_vars)
  complete_data <- data[complete.cases(data[, all_vars]), ]
  n             <- nrow(complete_data)
  n_missing     <- nrow(data) - n

  if (n < length(x_vars) + length(z_vars) + 1)
    stop("Insufficient complete cases for XGBoost analysis")

  all_predictors <- c(x_vars, z_vars)

  # Build feature matrix: ordered factors → integer ranks, others → numeric as-is
  X_list <- lapply(all_predictors, function(var) {
    col <- complete_data[[var]]
    if (is.ordered(col)) {
      matrix(as.numeric(col), ncol=1, dimnames=list(NULL, var))
    } else {
      matrix(col, ncol=1, dimnames=list(NULL, var))
    }
  })
  X <- do.call(cbind, X_list)

  y_vec <- complete_data[[y_var]]

  if (y_type == "continuous") {
    objective <- "reg:squarederror"
    labels    <- y_vec
    num_class <- NULL

  } else if (y_type == "binary") {
    objective <- "binary:logistic"
    labels    <- y_vec
    num_class <- NULL

  } else if (y_type == "ordinal") {
    labels    <- as.integer(y_vec) - 1
    num_class <- length(unique(labels))
    if (num_class == 2) {
      objective <- "binary:logistic"
      num_class <- NULL
    } else {
      objective <- "multi:softmax"
    }

  } else {
    stop("Unknown y_type: ", y_type)
  }

  nrounds   <- if ("nrounds"    %in% names(params)) params$nrounds    else 100
  max_depth <- if ("max_depth"  %in% names(params)) params$max_depth  else 6
  eta       <- if ("eta"        %in% names(params)) params$eta        else 0.3

  tryCatch({
    dtrain     <- xgb.DMatrix(data=X, label=labels)
    xgb_params <- list(objective=objective, max_depth=max_depth, eta=eta)
    if (!is.null(num_class)) xgb_params$num_class <- num_class

    xgb_model  <- xgboost(data=dtrain, params=xgb_params, nrounds=nrounds, verbose=0)
    imp_matrix <- xgb.importance(model=xgb_model)

    importance_scores <- setNames(numeric(length(all_predictors)), all_predictors)
    for (var in all_predictors) {
      var_features <- grep(paste0("^", var, "$"), imp_matrix$Feature, value=TRUE)
      importance_scores[var] <- sum(imp_matrix$Gain[imp_matrix$Feature %in% var_features], na.rm=TRUE)
    }

    importance_vals <- importance_scores[x_vars]
    names(importance_vals) <- x_vars

    if (verbose) {
      miss_str <- if (n_missing > 0) paste0(", ", n_missing, " missing") else ""
      message("\nXGBoost: n = ", n, miss_str,
              ", nrounds = ", nrounds, ", objective = ", objective)
    }

    return(list(
      importance       = importance_vals,
      nrounds          = nrounds,
      max_depth        = max_depth,
      eta              = eta,
      objective        = objective,
      n                = n,
      n_missing        = n_missing,
      missing_strategy = "listwise",
      all_importance   = importance_scores,
      model            = xgb_model
    ))

  }, error = function(e) {
    warning("Error computing XGBoost importance: ", e$message)
    importance_vals <- setNames(rep(NA_real_, length(x_vars)), x_vars)
    return(list(importance=importance_vals, n=n, error=e$message))
  })
}
