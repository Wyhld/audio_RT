
# 🧹 Clean Environment ----
rm(list = ls())            # Remove all objects
graphics.off()             # Close all graphics
cat("\014")                # Clear the console


library(tidyverse)
# 1. Load required packages (install if missing)
if (!require(car))    install.packages("car");    library(car)      # for Levene’s test (variance homogeneity)
if (!require(nortest))install.packages("nortest");library(nortest)  # for Anderson–Darling normality
if (!require(moments))install.packages("moments");library(moments) # for skewness & kurtosis
if (!require(gvlma))  install.packages("gvlma");  library(gvlma)    # omnibus linear‐model checks

data <- read_csv("data.csv")


# 2. Define your variable (and grouping factor, if relevant)
x <- data$normaliced_rt   # replace with your column
g <- data$with_noise   # uncomment and replace if you have groups

# 3. Outlier detection
boxplot(x, main = "Boxplot of x")                         # → boxplot: shows median, IQR, whiskers, and points beyond whiskers as outliers
outliers <- boxplot.stats(x)$out                          # → numeric vector of values outside the whiskers
print(outliers)                                           # → prints detected outlier values to console

# 4a. Histogram + density
hist(x, prob = TRUE,main = "Histogram of x with Density")# → histogram of x (y-axis = density)
lines(density(x), lwd = 2)                                # → adds kernel density curve over histogram

# 4b. Q–Q plot
qqnorm(x)                                                 # → Q–Q plot: sample quantiles vs. theoretical normal quantiles
qqline(x, col = "steelblue", lwd = 2)                    # → reference line; deviations indicate non-normality

# 4c. Shapiro–Wilk test (n ≤ 5000)
sw <- shapiro.test(x)                                     # → list with statistic W and p.value
print(sw)                                                 # → prints W and p-value (< .05 = reject normality)

# 4d. Anderson–Darling test
ad <- ad.test(x)                                          # → list with statistic A and p.value
print(ad)                                                 # → prints A and p-value (< .05 = reject normality)

# 4e. Skewness & kurtosis
skw <- skewness(x)                                        # → numeric skewness (0 = perfect symmetry)
krt <- kurtosis(x)                                        # → numeric kurtosis (3 = normal tails)
cat("Skewness:", skw, "\n", "Kurtosis:", krt, "\n")       # → prints skewness and kurtosis

# 5. Homogeneity of variances (if using groups)
# levene <- leveneTest(x ~ g, data = data)                # → ANOVA table: F-value, df1, df2, p-value (> .05 = equal variances)
# bartlett <- bartlett.test(x ~ g, data = data)           # → Bartlett’s K-squared, df, and p-value (> .05 = equal variances)
# print(levene); print(bartlett)

# 6. Omnibus check of linear‐model assumptions
# model <- lm(x ~ g, data = data)
# gvlma_res <- gvlma(model)                               # → gvlma object with p-values for skewness, kurtosis, link, heteroscedasticity, and global test
# summary(gvlma_res)                                       # → prints summary of each assumption test and overall model fit
