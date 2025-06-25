# 🧹 Clean Environment ---------------------------------------------------
# Clear the workspace, close all plots, and reset the console
rm(list = ls())         # Remove all objects
graphics.off()          # Close any open graphics devices
cat("\014")           # Clear the console

# 1. Load required packages ---------------------------------------------
library(tidyverse)       # data wrangling & ggplot2
library(lme4)            # fitting GLMMs

# Reproducible random seed
set.seed(123)

# 2. Read and preprocess data ------------------------------------------
data <- read_csv("data.csv") %>%
  filter(response == TRUE, !is.na(reaction_time)) %>%
  mutate(
    id         = factor(id),
    with_noise = factor(with_noise, levels = c(FALSE, TRUE))
  )

# 3. Fit Gamma-family GLMM ---------------------------------------------
mod <- glmer(
  reaction_time ~ with_noise + (1 | id),
  family  = Gamma(link = "log"),
  data    = data,
  control = glmerControl(optimizer = "bobyqa")
)
summary(mod)

# 4. Extract fixed effect ------------------------------------------------
fe <- coef(summary(mod))["with_noiseTRUE", , drop = FALSE]
print(fe)
ratio <- exp(fixef(mod)["with_noiseTRUE"])
cat("Back-transformed ratio:", ratio, "\n")

# 5. Generate predictions ------------------------------------------------
newdata <- tibble(with_noise = c(FALSE, TRUE))
pred    <- predict(mod, newdata, re.form = NA, type = "response", se.fit = TRUE)
newdata <- newdata %>%
  mutate(
    fit   = pred$fit,
    se    = pred$se.fit,
    lower = fit - 1.96 * se,
    upper = fit + 1.96 * se
  )

# 6. Violin distribution + model estimates -----------------------
p1 <- ggplot(data, aes(x = with_noise, y = reaction_time, fill = with_noise)) +
  geom_violin(alpha = 0.3, width = 0.8, color = NA) +
  geom_jitter(width = 0.1, size = 1, alpha = 0.2, color = "gray40") +
  geom_point(
    data        = newdata,
    aes(x        = with_noise, y = fit),
    inherit.aes = FALSE,
    color       = "white",
    size        = 4,
    shape       = 21,
    stroke      = 1.5
  ) +
  geom_errorbar(
    data        = newdata,
    aes(x        = with_noise, ymin = lower, ymax = upper),
    inherit.aes = FALSE,
    width       = 0.2,
    size        = 1.2,
    color       = "white"
  ) +
  scale_x_discrete(labels = c("No Noise", "Noise")) +
  scale_fill_manual(values = c("steelblue", "tomato")) +
  labs(
    x        = NULL,
    y        = "Reaction Time (s)",
    title    = "Distribution of RTs by Condition",
    subtitle = "Violin = RT distribution; white = GLMM means ±95% CI"
  ) +
  theme_light(base_size = 14) +
  theme(
    legend.position = "none",
    plot.title      = element_text(face = "bold", hjust = 0.5),
    plot.subtitle   = element_text(hjust = 0.5)
  )
print(p1)
