## -----------------------------------------------------------------------------
library(keydrivers)
data(mtcars)


## -----------------------------------------------------------------------------
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
              xgboost_   = TRUE,
              verbose    = FALSE)

print(result)


## -----------------------------------------------------------------------------
#| warning: false
mtcars$high_mpg <- as.integer(mtcars$mpg > median(mtcars$mpg))

result_bin <- kda(high_mpg ~ disp + hp + wt + drat,
                  data    = mtcars,
                  corr    = TRUE,
                  beta    = TRUE,
                  useful  = TRUE,
                  shapley = TRUE,
                  verbose = FALSE)

print(result_bin)


## -----------------------------------------------------------------------------
mtcars$mpg_tier <- cut(mtcars$mpg,
                       breaks         = quantile(mtcars$mpg, c(0, 1/3, 2/3, 1)),
                       labels         = c("low", "mid", "high"),
                       include.lowest = TRUE)
mtcars$mpg_tier <- factor(mtcars$mpg_tier, ordered = TRUE)

result_ord <- kda(mpg_tier ~ disp + hp + wt + drat,
                  data    = mtcars,
                  corr    = TRUE,
                  beta    = TRUE,
                  useful  = TRUE,
                  shapley = TRUE,
                  verbose = FALSE)

print(result_ord)


## -----------------------------------------------------------------------------
result_boot <- kda_boot(mpg ~ disp + hp + wt + drat,
                        data       = mtcars,
                        B          = 200,
                        conf_level = 0.95,
                        seed       = 42,
                        corr       = TRUE,
                        beta       = TRUE,
                        randforest = TRUE,
                        rf_params  = list(ntree = 500))

print(result_boot)


## -----------------------------------------------------------------------------
# Point estimates from the continuous example
plot(result)


## -----------------------------------------------------------------------------
# Bootstrap result with CIs — custom colors and background
plot(result_boot,
     colors   = c(corr = "steelblue", beta = "tomato", rf = "forestgreen"),
     bg_color = "#f8f8f8")


## -----------------------------------------------------------------------------
#| eval: false
# library(ggplot2)
# plot(result) + ggtitle("Key Drivers of Fuel Efficiency")


## -----------------------------------------------------------------------------
#| eval: false
# library(ggplot2)
# 
# for (v in c("disp", "hp", "wt", "drat")) {
#   p <- ggplot(mtcars, aes(x = .data[[v]], y = mpg)) +
#     geom_point() +
#     geom_smooth(method = "loess", se = TRUE) +
#     geom_smooth(method = "lm", se = FALSE, color = "red", linetype = "dashed") +
#     ggtitle(v)
#   print(p)
# }


## -----------------------------------------------------------------------------
#| eval: false
# library(randomForest)
# library(pdp)
# 
# rf_model <- randomForest(mpg ~ disp + hp + wt + drat, data = mtcars, ntree = 1000)
# partial(rf_model, pred.var = "wt", plot = TRUE, rug = TRUE)


## -----------------------------------------------------------------------------
#| eval: false
# library(mgcv)
# 
# m_lm  <- lm(mpg ~ disp + hp + wt + drat, data = mtcars)
# m_gam <- gam(mpg ~ s(disp) + s(hp) + s(wt) + s(drat), data = mtcars)
# 
# summary(m_lm)$r.squared
# summary(m_gam)$r.sq   # materially higher = non-linearity matters


## -----------------------------------------------------------------------------
#| eval: false
# partial(rf_model, pred.var = c("wt", "hp"), plot = TRUE, chull = TRUE)
# 
# # Confirm with a formal test in the linear model
# m_int <- lm(mpg ~ disp + hp + wt + drat + wt:hp, data = mtcars)
# anova(m_lm, m_int)

