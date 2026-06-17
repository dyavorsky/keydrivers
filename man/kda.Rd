\name{kda}
\alias{kda}

\title{Key Drivers Analysis}

\description{
\code{kda} performs key drivers analysis using multiple variable importance metrics. It computes importance scores for predictor variables in explaining an outcome variable, accommodating continuous, ordinal, and nominal data types.
}

\usage{
kda(form, data,
    corr = FALSE, beta = FALSE, useful = FALSE, jrw = FALSE,
    shapley = FALSE, shapex = FALSE, randforest = FALSE, xgboost = FALSE,
    cor_params = list(), beta_params = list(), useful_params = list(),
    jrw_params = list(), shapley_params = list(), shapex_params = list(),
    rf_params = list(), xgb_params = list())
}

\arguments{
\item{form}{A formula object with the syntax: \code{y ~ x1 + x2 + x3 | z1 + z2}, where \code{y} is the outcome variable, \code{x1, x2, x3} are the key driver variables for which importance will be measured, and \code{z1, z2} are optional control variables (after the | separator). If no controls are needed, use standard formula syntax: \code{y ~ x1 + x2 + x3}.}

\item{data}{A data frame containing all variables specified in the formula. Variables should be appropriately typed: numeric for continuous, ordered factors for ordinal, and factors for nominal.}

\item{corr}{Logical; if \code{TRUE}, compute bivariate correlations. Method selected automatically based on variable types: Pearson for continuous-continuous pairs; polyserial for continuous-ordinal pairs; polychoric for ordinal-ordinal pairs. The latter two are computed via \code{polycor::hetcor}.}

\item{beta}{Logical; if \code{TRUE}, compute standardized regression coefficients. Variables are scaled before fitting. Model type selected based on outcome: linear regression for continuous, ordinal regression for ordinal, multinomial for nominal.}

\item{useful}{Logical; if \code{TRUE}, compute usefulness (change in r-squared when each variable is removed). Currently only available for continuous outcomes.}

\item{jrw}{Logical; if \code{TRUE}, compute Johnson Relative Weights using \code{iopsych::relWt}. Only available for continuous outcomes with linear regression.}

\item{shapley}{Logical; if \code{TRUE}, compute Shapley/LMG values using \code{relaimpo::calc.relimp}. Only available for continuous outcomes with linear regression.}

\item{shapex}{Logical; if \code{TRUE}, compute SHAP (Shapley Additive Explanations) values using \code{fastshap::explain}. Available for all outcome types.}

\item{randforest}{Logical; if \code{TRUE}, compute Random Forest variable importance using \code{randomForest::randomForest}. Available for all outcome types.}

\item{xgboost}{Logical; if \code{TRUE}, compute XGBoost variable importance. Available for all outcome types.}

\item{cor_params}{Reserved for future use. Pass an empty list or omit.}

\item{beta_params}{Named list of additional parameters for regression (e.g., convergence criteria).}

\item{useful_params}{Named list of additional parameters for usefulness calculation.}

\item{jrw_params}{Named list of additional parameters for Johnson Relative Weights.}

\item{shapley_params}{Named list of additional parameters for Shapley/LMG calculation.}

\item{shapex_params}{Named list of additional parameters for SHAP (e.g., \code{nsim} for number of simulations, default 100).}

\item{rf_params}{Named list of parameters for Random Forest (e.g., \code{ntree=500}, \code{mtry=5}).}

\item{xgb_params}{Named list of parameters for XGBoost (e.g., \code{nrounds=100}, \code{max_depth=6}, \code{eta=0.3}).}
}

\details{
The function automatically detects variable types based on R object classes:
\itemize{
  \item Continuous: numeric vectors with more than 2 unique values
  \item Binary: \code{0/1} numeric vectors or logical (\code{TRUE/FALSE}) vectors
  \item Ordinal: ordered factors (\code{ordered=TRUE})
}

Nominal (unordered factor) variables are not supported for either the outcome or predictors and will produce an error.

Control variables (z) specified after the | separator are included in all regression-based methods but not in simple bivariate correlations.

Missing values are handled differently by method:
\itemize{
  \item Correlations: pairwise deletion (use all available pairs)
  \item Regression-based methods: listwise deletion (complete cases only)
}

Each sub-function returns sample size information and details about missing value handling.

Available methods:
\itemize{
  \item \strong{Correlations}: Pearson (continuous-continuous), polyserial (continuous-ordinal), polychoric (ordinal-ordinal) via \code{polycor::hetcor}
  \item \strong{Standardized Betas}: Scaled regression coefficients from lm (continuous), glm binomial (binary), or polr (ordinal)
  \item \strong{Usefulness}: Change in R² when each predictor is removed (continuous y only)
  \item \strong{Johnson Relative Weights}: Approximation to Shapley values for linear regression (continuous y only)
  \item \strong{Shapley/LMG}: Exact Shapley values via relaimpo (continuous y only)
  \item \strong{SHAP}: Shapley Additive Explanations for any model type
  \item \strong{Random Forest}: Variable importance from random forest models
  \item \strong{XGBoost}: Gain-based importance from gradient boosting
}
}

\value{
A list with the following components:
\item{importance}{A matrix with one row per x variable and one column per enabled method, containing the importance scores.}
\item{formula}{The input formula.}
\item{y_var}{Name of the outcome variable.}
\item{x_vars}{Vector of predictor variable names.}
\item{z_vars}{Vector of control variable names (if any).}
\item{y_type}{Type of outcome variable ("continuous", "ordinal", or "nominal").}
\item{x_types}{Named vector of types for each x variable.}
\item{correlations}{Metadata from correlation analysis (if \code{corr=TRUE}), including correlation methods used, sample sizes, and correlation values.}
\item{betas}{Metadata from regression analysis (if \code{beta=TRUE}), including model type, R², sample size, and fitted model.}
\item{usefulness}{Metadata from usefulness analysis (if \code{useful=TRUE}), including full model R² and sample size.}
\item{jrw}{Metadata from JRW analysis (if \code{jrw=TRUE}), including R² and all relative weights.}
\item{shapley}{Metadata from Shapley analysis (if \code{shapley=TRUE}), including all LMG values.}
\item{shapex}{Metadata from SHAP analysis (if \code{shapex=TRUE}), including number of simulations and fitted model.}
\item{randomforest}{Metadata from Random Forest (if \code{randforest=TRUE}), including ntree, mtry, and performance metrics.}
\item{xgboost}{Metadata from XGBoost (if \code{xgboost=TRUE}), including nrounds, max_depth, eta, and all feature importance scores.}
}

\examples{
# Example with continuous outcome
data(mtcars)
result <- kda(mpg ~ wt + hp + drat | cyl, data = mtcars,
              corr = TRUE, beta = TRUE, useful = TRUE)
print(result$importance)

# Example with ordinal outcome (requires ordered factor)
# iris$Sepal.Length.cat <- cut(iris$Sepal.Length, breaks=3,
#                               labels=c("Low", "Med", "High"), ordered=TRUE)
# result <- kda(Sepal.Length.cat ~ Sepal.Width + Petal.Length | Species,
#               data = iris, corr = TRUE, beta = TRUE, randforest = TRUE)

# Example with Random Forest parameters
# result <- kda(mpg ~ wt + hp + drat, data = mtcars,
#               randforest = TRUE, rf_params = list(ntree=1000, mtry=2))

# Example with custom correlation missing value handling
# result <- kda(mpg ~ wt + hp + drat, data = mtcars,
#               corr = TRUE, cor_params = list(use="complete.obs"))
}

\references{
Johnson, J. W. (2000). A heuristic method for estimating the relative weight of predictor variables in multiple regression. \emph{Multivariate Behavioral Research}, 35(1), 1-19.

Lindeman, R. H., Merenda, P. F., & Gold, R. Z. (1980). \emph{Introduction to bivariate and multivariate analysis}. Scott, Foresman.

Lundberg, S. M., & Lee, S. I. (2017). A unified approach to interpreting model predictions. \emph{Advances in Neural Information Processing Systems}, 30.
}

\author{Dan Yavorsky}