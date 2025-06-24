
# 🧹 Clean Environment ----
rm(list = ls())            # Remove all objects
graphics.off()             # Close all graphics
cat("\014")                # Clear the console

# 1. Load packages ----------------------------------------------------
library(tidyverse)    # data wrangling & ggplot
library(lme4)         # GLMM
library(DHARMa)       # residual diagnostics
library(rstatix)      # non-parametric tests
library(moments)      # skewness/kurtosis
library(nortest)      # Anderson–Darling

# 2. Read in your data ------------------------------------------------
# adjust the path if needed
data <- read_csv("data.csv")

# quick peek
glimpse(data)
summary(data$reaction_time)


# 5. Assumption checks on log(RT) -------------------------------------
# 5a) normality
logRT <- log(data_trim$reaction_time)
shapiro.test(logRT)        # expect p < .05 → non-normal
ad.test(logRT)             # expect p < .05
cat("Skew:", skewness(logRT), "Kurtosis:", kurtosis(logRT), "\n")

# 5b) homogeneity of variance (just sanity; paired design)
# not strictly needed here since we’ll use GLMM, but for completeness:
data_trim %>% levene_test(reaction_time ~ with_noise)

# 6. Fit a Gamma‐GLMM -------------------------------------------------
mod <- glmer(
  reaction_time ~ with_noise + (1 | id),
  family = Gamma(link = "log"),
  data   = data_trim,
  control= glmerControl(optimizer = "bobyqa")
)

summary(mod)

# 7. Model diagnostics via DHARMa -------------------------------------
sim <- simulateResiduals(mod)
plot(sim)                             # check uniformity, dispersion, zero-inflation
testDispersion(sim)                   # expect p > .05 if no overdispersion

# 8. If over-dispersed: add obs-level RE --------------------------------
if (testDispersion(sim)$p.value < .05) {
  data_trim$rowID <- factor(seq_len(nrow(data_trim)))
  mod2 <- update(mod, . ~ . + (1 | rowID))
  sim2 <- simulateResiduals(mod2)
  print(testDispersion(sim2))         # should now pass
  mod <- mod2                         # switch to the improved model
}

# 9. Summarize & interpret --------------------------------------------
# fixed-effect test:
coef(summary(mod))["with_noiseTRUE", , drop=FALSE]  

# back-transform to a ratio:
exp(fixef(mod)["with_noiseTRUE"])     # e.g. 1.10 → 10% slower with noise

# 10. Non-parametric backup: paired Wilcoxon ---------------------------
# only if you want a distribution-free check:
data_trim %>%
  wilcox_test(
    reaction_time ~ with_noise,
    paired = TRUE
  ) %>%
  add_significance()
