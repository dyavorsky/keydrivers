\name{kda}
\alias{kda}

\title{Key Drivers Analysis}

\description{
Computes variable importance scores for a set of key driver predictors relative
to an outcome variable, using up to eight complementary methods. Supports
continuous, binary (0/1), and ordinal outcomes; selects the appropriate model
for each method automatically.
}

\usage{
kda(form, data,
    corr = FALSE, beta = FALSE, useful = FALSE, jrw = FALSE,
    shapley = FALSE, shapex = FALSE, randforest = FALSE, xgboost_ = FALSE,
    verbose = TRUE,
    cor_params = list(), beta_params = list(), useful_params = list(),
    jrw_params = list(), shapley_params = list(), shapex_params = list(),
    rf_params = list(), xgb_params = list())
}

\arguments{
\item{form}{Formula with the syntax \code{y ~ x1 + x2 + x3 | z1 + z2}, where
  \code{y} is the outcome, \code{x1, x2, x3} are key driver variables whose
  importance will be measured, and \code{z1, z2} are optional control variables
  (placed after \code{|}). Without controls, use standard syntax:
  \code{y ~ x1 + x2 + x3}.}

\item{data}{Data frame containing all variables in the formula.}

\item{corr}{Logical; compute bivariate correlations. Pearson for
  continuous/binary pairs; polyserial or polychoric (via \code{polycor::hetcor})
  when any ordinal variable is involved. Uses pairwise deletion.}

\item{beta}{Logical; compute standardized regression coefficients. Predictors
  are scaled before fitting. Model: \code{lm} (continuous y),
  \code{glm(binomial)} (binary y), \code{polr} (ordinal y).}

\item{useful}{Logical; compute usefulness — the drop in R² (or McFadden
  pseudo-R²) when each predictor is removed from the full model. Model:
  \code{lm} (continuous y), \code{glm(binomial)} (binary y),
  \code{polr} (ordinal y).}

\item{jrw}{Logical; compute Johnson Relative Weights via \code{iopsych::relWt}.
  Applicable to continuous and binary outcomes only; returns \code{NA} with a
  warning for ordinal outcomes.}

\item{shapley}{Logical; compute Shapley/LMG values via the companion
  \code{shapley} package. Averages marginal R² contributions over all predictor
  orderings. Supports all three outcome types using \code{lm} (continuous),
  \code{glm(binomial)} (binary), or \code{polr} (ordinal).}

\item{shapex}{Logical; compute SHAP (Shapley Additive Explanations) values via
  \code{fastshap::explain}. Importance is mean absolute SHAP value per
  predictor. Model: \code{lm} (continuous y), \code{glm(binomial)} (binary y),
  \code{polr} (ordinal y).}

\item{randforest}{Logical; compute Random Forest variable importance via
  \code{randomForest::randomForest}. Regression forest for continuous y;
  classification forest for binary/ordinal y.}

\item{xgboost_}{Logical; compute XGBoost gain-based importance. Objective:
  \code{reg:squarederror} (continuous y), \code{binary:logistic} (binary y),
  \code{multi:softmax} (ordinal y with 3+ levels).}

\item{verbose}{Logical (default \code{TRUE}); print a summary header and
  per-method messages (sample size, model type, R²) to \code{stderr} via
  \code{message()}.}

\item{cor_params}{Reserved for future use.}

\item{beta_params}{Reserved for future use.}

\item{useful_params}{Reserved for future use.}

\item{jrw_params}{Reserved for future use.}

\item{shapley_params}{Reserved for future use.}

\item{shapex_params}{Named list of parameters for SHAP. Currently recognised:
  \code{nsim} (integer, number of Monte Carlo simulations; default \code{100}).}

\item{rf_params}{Named list of parameters for Random Forest. Passed to
  \code{randomForest()}. Commonly used: \code{ntree} (default \code{500}),
  \code{mtry}.}

\item{xgb_params}{Named list of parameters for XGBoost. Commonly used:
  \code{nrounds} (default \code{100}), \code{max_depth} (default \code{6}),
  \code{eta} (default \code{0.3}).}
}

\details{
Variable types are detected automatically from R class:
\itemize{
  \item \strong{Continuous}: numeric vectors whose values are not exclusively 0 and 1.
  \item \strong{Binary}: numeric vectors containing only 0 and 1, or logical vectors.
  \item \strong{Ordinal}: ordered factors (\code{ordered = TRUE}).
  \item \strong{Nominal}: unordered factors — \strong{blocked}. An error is thrown
    if a nominal variable appears as the outcome or a predictor. Recode as
    numeric (0/1 for binary) or ordered factor before use.
}

Logical outcome/predictor variables are converted to integer 0/1 before any
method is called.

Ordinal predictor variables are converted to integer ranks (via
\code{as.numeric()}) before being passed to regression-based methods
(betas, usefulness, JRW, Shapley, SHAP, RF, XGBoost).

Missing values:
\itemize{
  \item \strong{Pairwise deletion}: bivariate correlations — each y/x pair
    filtered independently.
  \item \strong{Listwise deletion}: all regression-based methods — rows with
    any missing value across all model variables are dropped.
}
}

\value{
A list of class \code{"kda"} with components:
\item{importance}{Matrix with one row per key driver variable and one column per
  enabled method, containing importance scores.}
\item{formula}{The input formula.}
\item{y_var}{Name of the outcome variable.}
\item{x_vars}{Character vector of key driver variable names.}
\item{z_vars}{Character vector of control variable names (empty if none).}
\item{y_type}{Detected type of the outcome: \code{"continuous"}, \code{"binary"},
  or \code{"ordinal"}.}
\item{x_types}{Named character vector of detected types for each key driver.}
\item{correlations}{Correlation metadata (if \code{corr = TRUE}): importance
  scores, correlation methods used per variable, and per-pair sample sizes.}
\item{betas}{Beta metadata (if \code{beta = TRUE}): importance, model type,
  R², n, n_missing, fitted model.}
\item{usefulness}{Usefulness metadata (if \code{useful = TRUE}): importance,
  full-model R², n, n_missing, fitted model.}
\item{jrw}{JRW metadata (if \code{jrw = TRUE}): importance, R², n, n_missing,
  all relative weights including controls.}
\item{shapley}{Shapley metadata (if \code{shapley = TRUE}): importance,
  model type, full-model R², n, n_missing.}
\item{shapex}{SHAP metadata (if \code{shapex = TRUE}): importance, model type,
  nsim, n, n_missing, mean absolute SHAP for all predictors, fitted model.}
\item{randomforest}{RF metadata (if \code{randforest = TRUE}): importance,
  ntree, mtry, performance metric (mean OOB R² or OOB accuracy), n, n_missing.}
\item{xgboost}{XGBoost metadata (if \code{xgboost_ = TRUE}): importance,
  nrounds, max_depth, eta, objective, n, n_missing, gain scores for all
  predictors.}
}

\seealso{
\code{\link{kda_boot}} for bootstrap confidence intervals around importance scores.
}

\examples{
data(mtcars)

# Continuous outcome — all deterministic methods
result <- kda(mpg ~ disp + hp + wt + drat,
              data    = mtcars,
              corr    = TRUE,
              beta    = TRUE,
              useful  = TRUE,
              jrw     = TRUE,
              shapley = TRUE,
              verbose = FALSE)
print(result)

# With a control variable and Random Forest tuning
result2 <- kda(mpg ~ disp + hp + wt | am,
               data       = mtcars,
               randforest = TRUE,
               rf_params  = list(ntree = 1000),
               verbose    = FALSE)

# Binary outcome
mtcars$high_mpg <- as.integer(mtcars$mpg > median(mtcars$mpg))
result_bin <- kda(high_mpg ~ disp + hp + wt,
                  data    = mtcars,
                  corr    = TRUE,
                  beta    = TRUE,
                  useful  = TRUE,
                  verbose = FALSE)
}

\references{
Johnson, J. W. (2000). A heuristic method for estimating the relative weight of
predictor variables in multiple regression. \emph{Multivariate Behavioral
Research}, 35(1), 1--19.

Lindeman, R. H., Merenda, P. F., & Gold, R. Z. (1980). \emph{Introduction to
bivariate and multivariate analysis}. Scott, Foresman.

Lundberg, S. M., & Lee, S. I. (2017). A unified approach to interpreting model
predictions. \emph{Advances in Neural Information Processing Systems}, 30.
}

\author{Dan Yavorsky}
