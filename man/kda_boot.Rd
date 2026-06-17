\name{kda_boot}
\alias{kda_boot}

\title{Bootstrap Confidence Intervals for Key Drivers Analysis}

\description{
Wraps \code{\link{kda}} to compute percentile bootstrap confidence intervals
for every importance score. Runs \code{kda()} once on the full data for point
estimates, then \code{B} times on bootstrap resamples, and returns the
\code{conf_level} percentile interval for each (variable, method) cell in
the importance matrix.
}

\usage{
kda_boot(form, data, B = 200, conf_level = 0.95, seed = NULL, ...)
}

\arguments{
\item{form}{Formula passed directly to \code{kda()}. See \code{\link{kda}} for
  syntax details.}

\item{data}{Data frame passed directly to \code{kda()}.}

\item{B}{Integer; number of bootstrap resamples (default \code{200}).}

\item{conf_level}{Numeric in (0, 1); confidence level for the intervals
  (default \code{0.95} for 95\% CIs).}

\item{seed}{Optional integer; passed to \code{set.seed()} before the first
  \code{kda()} call for reproducibility. When set, the full run (point
  estimates and all bootstrap iterations) is deterministic, including
  stochastic methods (RF, XGBoost, SHAP).}

\item{...}{Additional arguments passed to every \code{kda()} call: method
  flags (\code{corr}, \code{beta}, \code{randforest}, etc.) and tuning
  parameters (\code{rf_params}, \code{xgb_params}, \code{shapex_params}).
  \code{verbose} is forced to \code{FALSE} for all calls.}
}

\details{
The percentile bootstrap is used: the lower and upper CI bounds for each
importance score are the \code{(1 - conf_level) / 2} and
\code{1 - (1 - conf_level) / 2} quantiles of its bootstrap distribution.

Bootstrap iterations that fail (e.g., due to a degenerate resample) are
silently dropped. If the number of successful iterations is less than
\code{B}, a warning is issued and both \code{B} and \code{B_requested} are
returned so the discrepancy is visible.

\strong{Runtime considerations}: for stochastic methods, reduce per-iteration
cost via \code{rf_params = list(ntree = 100)},
\code{xgb_params = list(nrounds = 50)}, or
\code{shapex_params = list(nsim = 50)} when \code{B} is large.
}

\value{
A list of class \code{"kda_boot"} with components:
\item{estimate}{The \code{\link{kda}} result from the full (non-resampled) data.}
\item{ci_lower}{Matrix of lower CI bounds; same row/column structure as
  \code{estimate$importance}.}
\item{ci_upper}{Matrix of upper CI bounds; same structure as \code{ci_lower}.}
\item{B}{Number of successful bootstrap iterations used to compute the CIs.}
\item{B_requested}{The \code{B} argument as supplied.}
\item{conf_level}{The confidence level used.}
}

\seealso{
\code{\link{kda}} for point estimates without bootstrapping.
}

\examples{
data(mtcars)

result <- kda_boot(mpg ~ disp + hp + wt + drat,
                   data       = mtcars,
                   B          = 50,
                   conf_level = 0.95,
                   seed       = 42,
                   corr       = TRUE,
                   beta       = TRUE,
                   randforest = TRUE,
                   rf_params  = list(ntree = 200))
print(result)

# Access components directly
result$estimate$importance   # point estimates
result$ci_lower              # lower bounds
result$ci_upper              # upper bounds
}

\author{Dan Yavorsky}
