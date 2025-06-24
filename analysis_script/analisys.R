
# 🧹 Clean Environment ----
rm(list = ls())            # Remove all objects
graphics.off()             # Close all graphics
cat("\014")                # Clear the console

# 🚧 Optional: Detach all non-base packages (if needed)
if (!is.null(sessionInfo()$otherPkgs)) {
  invisible(lapply(paste0("package:", names(sessionInfo()$otherPkgs)), detach, character.only = TRUE, unload = TRUE))
}
library(lme4)
library(tidyverse)

data <- read_csv("data.csv")
data$with_noise <- factor(data$with_noise)

mod <- glmer(reaction_time ~ with_noise + (1|id),
              family = Gamma(link="log"),
              data = data)
mod_slope <- glmer(
  reaction_time ~ with_noise + 
    (1 + with_noise | id),        # random intercept + slope
  family = Gamma(link = "log"),
  data   = data,
  control = glmerControl(optimizer = "bobyqa")
)


plot(mod)                   # residuals vs. fitted → look for no clear pattern
qqnorm(residuals(mod)); qqline(residuals(mod))
