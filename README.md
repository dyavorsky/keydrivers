# keydrivers

An R package for key drivers analysis.

`kda()` measures the relative importance of predictors for a given outcome using eight complementary methods. It supports continuous, binary, and ordinal outcomes, selecting the appropriate model for each method automatically.

## Installation

```r
# install.packages("pak")
pak::pak("dyavorsky/shapley")   # companion package, install first
pak::pak("dyavorsky/keydrivers")
```

## Usage

```r
library(keydrivers)
data(mtcars)

result <- kda(mpg ~ disp + hp + wt + drat,
              data       = mtcars,
              corr       = TRUE,
              beta       = TRUE,
              useful     = TRUE,
              jrw        = TRUE,
              shapley    = TRUE,
              shapex     = TRUE,
              randforest = TRUE,
              rf_params  = list(ntree = 1000),
              xgboost_   = TRUE)

print(result)
```

The formula `y ~ x1 + x2 + x3 | z1 + z2` optionally separates key driver variables from control variables using a `|`. Controls are held fixed in all regression-based methods and excluded from bivariate correlations. Method-specific tuning is available via `_params` arguments: `rf_params` (`ntree`, `mtry`), `xgb_params` (`nrounds`, `max_depth`, `eta`), and `shapex_params` (`nsim`) are currently effective. `cor_params`, `beta_params`, `useful_params`, `jrw_params`, and `shapley_params` are accepted but not yet wired to any tunable parameters.

## Methods

| Flag | Method | Model(s) |
|------|--------|----------|
| `corr` | Bivariate correlations | Pearson / polyserial / polychoric |
| `beta` | Standardized regression coefficients | lm / glm(binomial) / polr |
| `useful` | Usefulness (ΔR²) | lm / glm(binomial) / polr |
| `jrw` | Johnson relative weights | lm (continuous and binary y only) |
| `shapley` | Shapley/LMG values | lm / glm(binomial) / polr |
| `shapex` | SHAP values | lm / glm(binomial) / polr |
| `randforest` | Random forest importance | randomForest |
| `xgboost_` | XGBoost gain importance | xgboost |

## Variable Types

Variables are typed automatically from their R class:

| R Class | Detected Type |
|---------|---------------|
| `numeric` (values other than 0/1) | Continuous |
| `numeric` (only 0 and 1) or `logical` | Binary |
| `ordered factor` | Ordinal |
| `factor` (unordered) | Blocked — recode before use |

See `vignette("getting-started", package = "keydrivers")` for worked examples across all three outcome types.
