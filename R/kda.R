# ## Key Drivers Analysis
#
# Performs key drivers analysis using multiple variable importance metrics.
#
# ### Parameters
# - `form`: Formula with syntax `y ~ x1 + x2 + x3 | z1 + z2` where:
#   - y = outcome variable
#   - x1, x2, x3 = key drivers (importance measured)
#   - z1, z2 = control variables (optional, after |)
# - `data`: Data frame containing all variables in formula
# - `corr`: Compute bivariate correlations (logical)
# - `beta`: Compute standardized regression coefficients (logical)
# - `useful`: Compute usefulness / change in R² (logical)
# - `jrw`: Compute Johnson Relative Weights (logical)
# - `shapley`: Compute Shapley/LMG values (logical)
# - `shapex`: Compute SHAP values (logical)
# - `randforest`: Compute Random Forest importance (logical)
# - `xgboost_`: Compute XGBoost importance (logical)
# - `verbose`: Print progress messages during execution (logical, default TRUE)
# - `cor_params`: Parameters for correlations
# - `beta_params`: Parameters for regression
# - `useful_params`: Parameters for usefulness
# - `jrw_params`: Parameters for JRW
# - `shapley_params`: Parameters for Shapley
# - `shapex_params`: Parameters for SHAP
# - `rf_params`: Parameters for Random Forest (e.g., ntree, mtry)
# - `xgb_params`: Parameters for XGBoost (e.g., nrounds, max_depth, eta)
#
# ### Returns
# List of class "kda" containing:
# - `importance`: Matrix with rows = x variables, columns = methods
# - `correlations`: Metadata from correlation analysis (if corr=TRUE)
# - `betas`: Metadata from regression analysis (if beta=TRUE)
# - `usefulness`: Metadata from usefulness analysis (if useful=TRUE)
# - `jrw`: Metadata from JRW analysis (if jrw=TRUE)
# - `shapley`: Metadata from Shapley analysis (if shapley=TRUE)
# - `shapex`: Metadata from SHAP analysis (if shapex=TRUE)
# - `randomforest`: Metadata from Random Forest analysis (if randforest=TRUE)
# - `xgboost`: Metadata from XGBoost analysis (if xgboost_=TRUE)

kda <- function(form, data,
                corr=FALSE, beta=FALSE, useful=FALSE, jrw=FALSE,
                shapley=FALSE, shapex=FALSE, randforest=FALSE, xgboost_=FALSE,
                verbose=TRUE, normalize=TRUE,
                cor_params=list(), beta_params=list(), useful_params=list(),
                jrw_params=list(), shapley_params=list(), shapex_params=list(),
                rf_params=list(), xgb_params=list()) {

  # Parse formula to extract y, x_vars, z_vars
  parsed <- parse_kda_formula(form, data)
  y_var  <- parsed$y_var
  x_vars <- parsed$x_vars
  z_vars <- parsed$z_vars

  # Detect data types
  y_type  <- detect_var_type(data[[y_var]])
  x_types <- sapply(x_vars, function(x) detect_var_type(data[[x]]))

  if (y_type == "nominal") {
    stop("Nominal (unordered factor) outcome variables are not supported. ",
         "For binary outcomes, recode as numeric (0/1).")
  }

  nominal_x <- names(x_types[x_types == "nominal"])
  if (length(nominal_x) > 0) {
    stop("Nominal (unordered factor) x variables are not supported: ",
         paste(nominal_x, collapse=", "),
         ". Recode as numeric (0/1 for binary variables) or ordered factor.")
  }

  # Convert logical variables to integer 0/1 before dispatch
  for (var in c(y_var, x_vars, z_vars)) {
    if (is.logical(data[[var]])) data[[var]] <- as.integer(data[[var]])
  }

  if (verbose) {
    message("Key Drivers Analysis")
    message("Outcome: ", y_var, " (", y_type, ")")
    message("Drivers: ", paste(paste0(x_vars, " (", x_types, ")"), collapse=", "))
    if (length(z_vars) > 0)
      message("Controls: ", paste(z_vars, collapse=", "))
  }

  # Initialize results storage
  results <- list()
  importance_matrix <- matrix(NA, nrow=length(x_vars), ncol=0)
  rownames(importance_matrix) <- x_vars

  # Store metadata
  results$formula <- form
  results$y_var   <- y_var
  results$x_vars  <- x_vars
  results$z_vars  <- z_vars
  results$y_type  <- y_type
  results$x_types <- x_types

  # Call each sub-function if enabled
  if (corr) {
    cor_result <- sub_cor(y_var, x_vars, data, cor_params, verbose=verbose)
    results$correlations <- cor_result
    importance_matrix <- cbind(importance_matrix, corr=cor_result$importance)
  }

  if (beta) {
    beta_result <- sub_betas(y_var, x_vars, z_vars, data, y_type, beta_params, verbose=verbose)
    results$betas <- beta_result
    importance_matrix <- cbind(importance_matrix, beta=beta_result$importance)
  }

  if (useful) {
    useful_result <- sub_useful(y_var, x_vars, z_vars, data, y_type, useful_params, verbose=verbose)
    results$usefulness <- useful_result
    importance_matrix <- cbind(importance_matrix, usefulness=useful_result$importance)
  }

  if (jrw) {
    jrw_result <- sub_jrw(y_var, x_vars, z_vars, data, y_type, jrw_params, verbose=verbose)
    results$jrw <- jrw_result
    importance_matrix <- cbind(importance_matrix, jrw=jrw_result$importance)
  }

  if (shapley) {
    shapley_result <- sub_shapley(y_var, x_vars, z_vars, data, y_type, shapley_params, verbose=verbose)
    results$shapley <- shapley_result
    importance_matrix <- cbind(importance_matrix, shapley=shapley_result$importance)
  }

  if (shapex) {
    shapex_result <- sub_shapex(y_var, x_vars, z_vars, data, y_type, shapex_params, verbose=verbose)
    results$shapex <- shapex_result
    importance_matrix <- cbind(importance_matrix, shap=shapex_result$importance)
  }

  if (randforest) {
    rf_result <- sub_randomforest(y_var, x_vars, z_vars, data, y_type, rf_params, verbose=verbose)
    results$randomforest <- rf_result
    importance_matrix <- cbind(importance_matrix, rf=rf_result$importance)
  }

  if (xgboost_) {
    xgb_result <- sub_xgboost(y_var, x_vars, z_vars, data, y_type, xgb_params, verbose=verbose)
    results$xgboost <- xgb_result
    importance_matrix <- cbind(importance_matrix, xgb=xgb_result$importance)
  }

  if (normalize) {
    for (j in seq_len(ncol(importance_matrix))) {
      col_sum <- sum(importance_matrix[, j], na.rm = TRUE)
      if (!is.na(col_sum) && col_sum > 0)
        importance_matrix[, j] <- importance_matrix[, j] / col_sum * 100
    }
  }

  results$importance <- importance_matrix
  results$normalize  <- normalize
  results <- c(list(importance=results$importance), results[names(results) != "importance"])
  class(results) <- "kda"

  return(results)
}


# ## Parse KDA formula with | separator
#
# Extracts outcome, predictor, and control variables from custom formula syntax.
parse_kda_formula <- function(form, data) {
  form_str <- deparse(form)
  form_str <- paste(form_str, collapse=" ")

  sides <- strsplit(form_str, "~")[[1]]
  if (length(sides) != 2)
    stop("Formula must have format: y ~ x1 + x2 + ... | z1 + z2 + ...")

  y_side <- trimws(sides[1])
  rhs    <- trimws(sides[2])

  if (grepl("\\|", rhs)) {
    parts  <- strsplit(rhs, "\\|")[[1]]
    x_vars <- trimws(strsplit(trimws(parts[1]), "\\+")[[1]])
    z_vars <- trimws(strsplit(trimws(parts[2]), "\\+")[[1]])
  } else {
    x_vars <- trimws(strsplit(rhs, "\\+")[[1]])
    z_vars <- character(0)
  }

  y_var <- y_side

  all_vars     <- c(y_var, x_vars, z_vars)
  missing_vars <- setdiff(all_vars, names(data))
  if (length(missing_vars) > 0)
    stop("Variables not found in data: ", paste(missing_vars, collapse=", "))

  return(list(y_var=y_var, x_vars=x_vars, z_vars=z_vars))
}


# ## Detect variable type
#
# Returns "binary" for 0/1 numeric or logical, "ordinal" for ordered factors,
# "nominal" for unordered factors, "continuous" for other numeric.
detect_var_type <- function(x) {
  if (is.ordered(x)) {
    return("ordinal")
  } else if (is.factor(x)) {
    return("nominal")
  } else if (is.logical(x)) {
    return("binary")
  } else if (is.numeric(x)) {
    if (setequal(unique(na.omit(x)), c(0, 1))) return("binary")
    return("continuous")
  } else {
    stop("Unable to detect variable type. Must be numeric (continuous or 0/1 binary), logical, factor, or ordered factor.")
  }
}
