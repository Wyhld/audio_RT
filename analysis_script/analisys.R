# 🧹 Clean Environment ---------------------------------------------------
# Clear the workspace, close all plots, and reset the console
rm(list = ls())         # Remove all objects from the environment
graphics.off()          # Close any open graphics devices
cat("\014")           # Clear the console

# 1. Load required packages ---------------------------------------------
#   - tidyverse for data wrangling & ggplot
#   - lme4 for fitting GLMMs
#   - ggplot2 for custom plotting
library(tidyverse)
library(lme4)
library(ggplot2)

# Set a reproducible random seed for any jitter or simulation
set.seed(123)

# 2. Read and preprocess data ------------------------------------------
# Adjust the path to your CSV file as needed
data <- read_csv("data.csv")

# Optional: keep only trials where `response == TRUE`
data_true <- data %>%
  filter(response == TRUE)

# Ensure `with_noise` is a factor with levels FALSE (baseline) then TRUE
data <- data %>%
  mutate(with_noise = factor(with_noise, levels = c(FALSE, TRUE)))

# 3. Fit a Gamma-family GLMM with log link ----------------------------
#   - Fixed effect: noise condition
#   - Random intercept: subject ID (repeated measures)
mod <- glmer(
  reaction_time ~ with_noise + (1 | id),
  family  = Gamma(link = "log"),
  data    = data,
  control = glmerControl(optimizer = "bobyqa")  # robust optimizer
)

# Display model summary including AIC, random-effects, and fixed-effects
summary(mod)

# 4. Extract and interpret the fixed effect for `with_noiseTRUE` -------
fe <- coef(summary(mod))["with_noiseTRUE", , drop = FALSE]
print(fe)  # Estimate, Std. Error, z-value, p-value

# Back-transform the log-scale estimate to a multiplicative ratio
ratio <- exp(fixef(mod)["with_noiseTRUE"])
cat("Back-transformed ratio (noise / no-noise):", ratio, "\n")

# 5. Generate population-level predictions for plotting -----------------
# Build a new data frame for the two noise levels
newdata <- tibble(
  with_noise = factor(c(FALSE, TRUE), levels = levels(data$with_noise))
)

# Predict on the response scale (seconds) with standard errors
pred <- predict(
  mod,
  newdata = newdata,
  re.form = NA,        # exclude random effects (population-level)
  type    = "response",
  se.fit  = TRUE
)

# Append predictions and 95% CI bounds to `newdata`
newdata <- newdata %>%
  mutate(
    fit   = pred$fit,
    se    = pred$se.fit,
    lower = fit - 1.96 * se,  # Lower 95% CI
    upper = fit + 1.96 * se   # Upper 95% CI
  )

# 6. Create a publication-quality plot -------------------------------
#   - Gray jittered points for raw data
#   - Colored points & error bars for model estimates
#   - Clean theme, labeled axes, and legend on top
p <- ggplot() +
  # Raw reaction times (jittered for visibility)
  geom_jitter(
    data    = data,
    aes(x = with_noise, y = reaction_time),
    width   = 0.2,
    alpha   = 0.2,
    size    = 1,
    color   = "gray40"
  ) +
  
  # Model-predicted means colored by condition
  geom_point(
    data    = newdata,
    aes(x = with_noise, y = fit, color = with_noise),
    size    = 4,
    alpha   = 0.9
  ) +
  
  # 95% confidence intervals around predictions
  geom_errorbar(
    data    = newdata,
    aes(x = with_noise, ymin = lower, ymax = upper, color = with_noise),
    width   = 0.1,
    size    = 0.8,
    alpha   = 0.9
  ) +
  
  # Custom color palette and legend labels
  scale_color_manual(
    name   = "Condition",
    values = c("FALSE" = "steelblue", "TRUE" = "tomato"),
    labels = c("No Noise",   "Noise")
  ) +
  
  # X-axis labels and plot titles
  scale_x_discrete(labels = c("No Noise", "Noise")) +
  labs(
    x        = NULL,
    y        = "Reaction Time (s)",
    title    = "Effect of Noise on Reaction Times",
    subtitle = "Predicted means (points) ± 95% CI from Gamma-log GLMM with raw data overlaid"
  ) +
  
  # Publication-style theme adjustments
  theme_bw(base_size = 14) +
  theme(
    panel.grid.major   = element_blank(),
    panel.grid.minor   = element_blank(),
    axis.text.x        = element_text(size = 12),
    axis.text.y        = element_text(size = 12),
    legend.position    = "top",
    plot.title         = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle      = element_text(size = 12, hjust = 0.5)
  )

# Print the publication-quality plot
print(p)

# 7. Violin plot: full RT distribution + model estimates -----------
# A distributional raincloud: violin of raw RTs, overlaid with GLMM means and CIs

ggplot(data, aes(x = with_noise, y = reaction_time, fill = with_noise)) +
  # 1) Violin for the full RT distribution
  geom_violin(alpha = 0.3, width = 0.8, color = NA) +
  # 2) Raw observations
  geom_jitter(width = 0.1, size = 1, alpha = 0.2, color = "gray40") +
  # 3) Model-predicted means (white circles) – no inherited mapping
  geom_point(
    data        = newdata,
    aes(x        = with_noise, y = fit),
    inherit.aes = FALSE,
    color       = "white",
    size        = 4,
    shape       = 21,
    stroke      = 1.5
  ) +
  # 4) 95% CI bars around those means – no inherited mapping
  geom_errorbar(
    data        = newdata,
    aes(x        = with_noise, ymin = lower, ymax = upper),
    inherit.aes = FALSE,
    width       = 0.2,
    size        = 1.2,
    color       = "white"
  ) +
  # 5) Scale & labels
  scale_x_discrete(labels = c("No Noise", "Noise")) +
  scale_fill_manual(values = c("steelblue", "tomato")) +
  labs(
    x        = NULL,
    y        = "Reaction Time (s)",
    title    = "Distribution of RTs by Condition",
    subtitle = "Violin = full RT distribution; white = GLMM means ± 95% CI"
  ) +
  # 6) Stylized theme
  theme_light(base_size = 14) +
  theme(
    legend.position = "none",
    plot.title      = element_text(face = "bold", hjust = 0.5),
    plot.subtitle   = element_text(hjust = 0.5)
  )
