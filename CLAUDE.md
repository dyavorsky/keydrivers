# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an R package (`keydrivers`) that provides functions for key drivers analysis,
accommodating continuous, binary, and ordinal outcomes and predictors. Nominal
(unordered factor) variables are explicitly blocked. The package is in active development.

## R Package Development Commands

### Building and Checking
```r
# Build the package
devtools::build()

# Check the package for errors/warnings/notes
devtools::check()

# Install the package locally for testing
devtools::install()

# Load the package during development
devtools::load_all()
```

### Documentation
```r
# Build the package manual
devtools::build_manual()
```

### Testing
Currently no test suite exists. To add tests:
```r
# Set up testing infrastructure (run once)
usethis::use_testthat()

# Create a new test file
usethis::use_test("function-name")

# Run tests
devtools::test()
```

## Architecture

The package follows a **main function + sub-method pattern**, with two additional top-level
functions for bootstrapping and plotting:

- **Main function**: `kda()` in [R/kda.R](R/kda.R) serves as the entry point, accepting a
  formula, data, boolean flags for each analysis method, `verbose=TRUE`, and `normalize=TRUE`
- **Bootstrap wrapper**: `kda_boot()` in [R/kda_boot.R](R/kda_boot.R) calls `kda()` once on
  the full data for point estimates, then B times on bootstrap resamples to compute percentile
  CIs; returns a `"kda_boot"` object
- **Plot methods**: `plot.kda()` and `plot.kda_boot()` in [R/plot.kda.R](R/plot.kda.R) produce
  horizontal dot plots via ggplot2; drivers ordered top-to-bottom by mean importance; methods
  colored; CI lines drawn for `kda_boot` objects
- **Sub-functions**: Eight implemented methods, each in their own file:
  - `sub_cor.R` - Bivariate correlations: Pearson for continuous/binary pairs; polyserial or
    polychoric via `hetcor()` when any ordinal variable is involved
  - `sub_betas.R` - Standardized regression coefficients: `lm` (continuous y), `glm(binomial)`
    (binary y), `polr` (ordinal y); ordinal x → integer ranks before scaling
  - `sub_useful.R` - Usefulness (ΔR² when each variable is removed): `lm` + R² (continuous y),
    `glm(binomial)` + McFadden pseudo-R² (binary y), `polr` + McFadden pseudo-R² (ordinal y)
  - `sub_jrw.R` - Johnson Relative Weights via `iopsych::relWt`; continuous and binary y only
    (ordinal y returns NAs); ordinal x → integer ranks before matrix construction
  - `sub_shapley.R` - Shapley/LMG values; delegates to the `shapley` package (hand-rolled LMG
    engine); supports all three y types; ordinal x → integer ranks before calling shapley package
  - `sub_shapex.R` - SHAP values via `fastshap::explain`: `lm` (continuous y),
    `glm(binomial)` (binary y), `polr` (ordinal y)
  - `sub_randomforest.R` - Random Forest importance via `randomForest`; regression forest
    (continuous y), classification forest (binary/ordinal y)
  - `sub_xgboost.R` - XGBoost importance; `reg:squarederror` (continuous y),
    `binary:logistic` (binary y), `binary:logistic` or `multi:softmax` (ordinal y)

### Formula Syntax

The `kda()` function uses a custom formula syntax with a pipe separator:
```r
y ~ x1 + x2 + x3 | z1 + z2
```
- **y**: Outcome variable (left of ~)
- **x1, x2, x3**: Key driver variables whose importance will be measured (between ~ and |)
- **z1, z2**: Control variables (after |, optional)

If no controls are needed, use standard formula syntax: `y ~ x1 + x2 + x3`

The formula is parsed by `parse_kda_formula()` helper function which:
1. Splits on ~ to separate outcome from predictors
2. Splits on | to separate key drivers from controls
3. Validates all variables exist in the data

### Data Type Detection

Variables are automatically typed using `detect_var_type()`:
- **Binary**: `is.logical(x)` OR `setequal(unique(na.omit(x)), c(0, 1))` for numeric
- **Ordinal**: `is.ordered(x)` (ordered factor)
- **Continuous**: `is.numeric(x)` and not 0/1
- **Nominal**: `is.factor(x)` and not ordered — **blocked for both y and x with a clear error**

Logical variables are converted to integer 0/1 globally in `kda()` after type detection,
before dispatch to any sub-function.

### Control Variables

Control variables are used differently by method:
- **Not included**: Bivariate correlations (`sub_cor`)
- **Included**: All regression-based methods (betas, usefulness, JRW, Shapley, SHAP, RF, XGBoost)

### Missing Value Handling

- **Pairwise deletion**: Correlations (`sub_cor`) — each y-x pair filtered independently
- **Listwise deletion**: All regression-based methods — `complete.cases()` on all variables

Each sub-function returns `n` (sample size used) and `n_missing` (cases removed).

### Normalization

`kda()` accepts `normalize=TRUE` (default). When enabled, each method's importance column
is rescaled so it sums to 100 after all sub-functions have run. A score of 25 means that
variable accounts for 25% of total importance for that method. For Shapley/LMG, this equals
the percentage of full-model R² attributed to each predictor. Raw scores are preserved in the
per-method metadata lists (`result$shapley$importance`, etc.); only `result$importance` is
normalized. Set `normalize=FALSE` to return raw scores.

### Verbose Output

`kda()` accepts `verbose=TRUE` (default). When enabled, each sub-function emits
`message()` calls (to stderr, suppressible) reporting: method name, model type, n,
missing cases, and R² (or pseudo-R²). A summary header is also printed at the start.

### Return Structure

`kda()` returns a list of class `"kda"` with `print.kda()` and `plot.kda()` S3 methods:
```r
list(
  importance = matrix(...),  # Rows = x variables, Columns = enabled methods (normalized if normalize=TRUE)
  formula = ...,             # Input formula
  y_var = "...",             # Outcome variable name
  x_vars = c(...),           # Key driver variable names
  z_vars = c(...),           # Control variable names (if any)
  y_type = "...",            # "continuous", "binary", or "ordinal"
  x_types = c(...),          # Named vector of x variable types
  normalize = TRUE/FALSE,    # Whether importance matrix was normalized
  correlations = list(...),  # Metadata if corr=TRUE
  betas = list(...),         # Metadata if beta=TRUE
  # ... one element per enabled method
)
```

`kda_boot()` returns a list of class `"kda_boot"` with `print.kda_boot()` and
`plot.kda_boot()` S3 methods:
```r
list(
  estimate    = <kda object>,    # Full-data point estimates
  ci_lower    = matrix(...),     # Lower CI bounds, same shape as estimate$importance
  ci_upper    = matrix(...),     # Upper CI bounds
  B           = <integer>,       # Successful bootstrap iterations
  B_requested = <integer>,       # B argument as supplied
  conf_level  = <numeric>        # Confidence level (e.g., 0.95)
)
```

Each method's metadata list includes:
- `importance`: Named vector of raw (un-normalized) importance scores for x variables
- `n`: Sample size used
- `n_missing`: Number of cases removed due to missing values
- `missing_strategy`: "pairwise" or "listwise"
- `model_type`: Model fitted (e.g., "lm", "glm(binomial)", "polr")
- Method-specific fields (e.g., `r2`, `ntree`, `nrounds`, `objective`)

### Plotting

`plot.kda(x, colors=NULL, bg_color="white")` and `plot.kda_boot(x, colors=NULL, bg_color="white")`
produce ggplot2 horizontal dot plots. Drivers are ordered by mean normalized importance (largest
at top). `colors` accepts a named or unnamed character vector to override the default palette.
`bg_color` sets the panel and plot background. Both return a `ggplot` object that can be
extended with additional ggplot2 layers. CI lines are drawn automatically for `kda_boot` objects.

### Parameter Passing

Each method accepts a named list of parameters (e.g., `rf_params=list(ntree=1000, mtry=3)`):
- `cor_params` - Currently unused
- `beta_params` - Currently unused
- `useful_params` - Currently unused
- `jrw_params` - Currently unused
- `shapley_params` - Currently unused
- `shapex_params` - SHAP parameters (e.g., `nsim=100` for simulations)
- `rf_params` - Random Forest parameters (e.g., `ntree`, `mtry`)
- `xgb_params` - XGBoost parameters (e.g., `nrounds`, `max_depth`, `eta`)

## The `shapley` Package

Shapley/LMG computation is implemented in a standalone companion package at `../shapley`
(installed locally; `dyavorsky/shapley` on GitHub once published).

- **Exported function**: `shapley(y_var, x_vars, z_vars=character(0), data, y_type)`
- **Returns**: a `shapley_result` object with `values`, `r2`, `model_type`, `n`, `n_missing`
- **Engine**: `.shapley_engine()` — binary-indexed subset caching + Shapley weighting formula
  (O(2^p) R² evaluations; warns if p > 15)
- **Models**: lm + R² (continuous), glm(binomial) + McFadden pseudo-R² (binary),
  polr + McFadden pseudo-R² (ordinal)
- **Continuous y optimization**: pre-computes correlation matrix once; each subset's R²
  via Schur complement — replaces 2^p lm() calls with 2^p small matrix solves
- Install/update: `devtools::install("../shapley")`

## Dependencies

The package imports eight libraries (defined in [DESCRIPTION](DESCRIPTION)):
- `shapley` - Hand-rolled Shapley/LMG engine (companion package, `../shapley`)
- `iopsych` - Johnson Relative Weights via `relWt()`
- `polycor` - Polyserial and polychoric correlations via `hetcor()`
- `randomForest` - Random forest algorithms
- `xgboost` - Gradient boosting for variable importance
- `MASS` - Ordinal regression via `polr()`
- `fastshap` - SHAP values via `explain()`
- `ggplot2` - Plotting via `plot.kda()` and `plot.kda_boot()`

Functions are selectively imported via [NAMESPACE](NAMESPACE) using `importFrom()` directives.

## Installation

Install the `shapley` companion package first:
```r
devtools::install("../shapley")  # local
# or: remotes::install_github("dyavorsky/shapley")  # once on GitHub
```

Then install keydrivers:
```r
remotes::install_github("dyavorsky/keydrivers")
```

## Package Metadata

- Version: 0.0.2
- Minimum R version: 4.1
- License: MIT
- Maintained by: Dan Yavorsky (dyavorsky@gmail.com)
