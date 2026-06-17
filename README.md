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

By default (`normalize = TRUE`) each method's scores are rescaled to sum to 100, so a score of 25 means that variable accounts for 25% of total importance for that method. For Shapley/LMG values this equals the percentage of full-model R² attributed to each predictor. Set `normalize = FALSE` to return raw scores.

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

## Plotting

`plot()` works directly on `kda` and `kda_boot` objects. Drivers are ordered from most to least important; each method gets its own color; bootstrap CI lines appear automatically when available.

```r
# Point estimates only
plot(result)

# With custom colors and background
plot(result,
     colors   = c(correlation = "steelblue", beta = "tomato", shapley = "goldenrod"),
     bg_color = "#f5f5f5")

# With bootstrap CIs
plot(result_boot)
```

The return value is a `ggplot` object and can be extended with additional ggplot2 layers.

## Bootstrap Confidence Intervals

`kda_boot()` wraps `kda()` to add percentile bootstrap CIs for every importance score:

```r
result <- kda_boot(mpg ~ disp + hp + wt + drat,
                   data       = mtcars,
                   B          = 200,
                   conf_level = 0.95,
                   seed       = 42,
                   corr       = TRUE,
                   beta       = TRUE,
                   randforest = TRUE,
                   rf_params  = list(ntree = 500))

print(result)
```

`B` controls the number of resamples; `seed` makes results reproducible. For stochastic methods (RF, XGBoost, SHAP), reduce per-iteration cost with smaller `ntree`, `nrounds`, or `nsim` when `B` is large.

## Variable Types

Variables are typed automatically from their R class:

| R Class | Detected Type |
|---------|---------------|
| `numeric` (values other than 0/1) | Continuous |
| `numeric` (only 0 and 1) or `logical` | Binary |
| `ordered factor` | Ordinal |
| `factor` (unordered) | Blocked — recode before use |

See `vignette("getting-started", package = "keydrivers")` for worked examples across all three outcome types.
