
# 🧹 Clean Environment ----
rm(list = ls())            # Remove all objects
graphics.off()             # Close all graphics
cat("\014")                # Clear the console

# 🚧 Optional: Detach all non-base packages (if needed)
 if (!is.null(sessionInfo()$otherPkgs)) {
   invisible(lapply(paste0("package:", names(sessionInfo()$otherPkgs)), detach, character.only = TRUE, unload = TRUE))
 }

# Load required library
library(tidyverse)

# Set your folder path
folder_path <- "data/"

# Read and combine all CSVs
data <- list.files(path = folder_path, pattern = "\\.csv$", full.names = TRUE) %>%
  set_names(~ tools::file_path_sans_ext(basename(.))) %>%
  map_dfr(read_csv, .id = "source_file")

data <- data %>%
  rename(id = source_file) 

# Cleaning
data <- data %>%
  # Filter only the testing phase
  filter(phase != "training") %>%
  drop_na()

# Log transformation
data$normaliced_rt = log(data$reaction_time)
boxplot(data$normaliced_rt)

clean_data <- data %>%
  # (Optional) Hard bounds on raw RTs, e.g. exclude implausible values
  filter(reaction_time >= 0.100, reaction_time <= 3.000) %>%  
  group_by(id) %>%    # replace 'subject' with your ID column
  mutate(
    med_log    = median(normaliced_rt, na.rm = TRUE),
    mad_log    = mad(normaliced_rt, na.rm = TRUE),
    is_outlier = abs(normaliced_rt - med_log) > 3 * mad_log
  ) %>%
  filter(!is_outlier) %>%  # drop the extreme log-RTs
  ungroup() %>%
  # back-transform so your cleaned RTs are on the original scale
  mutate(reaction_time_clean = exp(normaliced_rt)) %>%
  select(-med_log, -mad_log, -is_outlier)

# View a quick summary
clean_data %>% 
  summarise(
    n_orig = nrow(data),
    n_clean = nrow(.),
    pct_removed = 100 * (n_orig - n_clean) / n_orig
  )

clean_data <- data %>%
  # (Optional) Hard bounds on raw RTs, e.g. exclude implausible values
  filter(reaction_time >= 0.100, reaction_time <= 3.000) %>%  
  group_by(id) %>%    # replace 'subject' with your ID column
  mutate(
    med_log    = median(normaliced_rt, na.rm = TRUE),
    mad_log    = mad(normaliced_rt, na.rm = TRUE),
    is_outlier = abs(normaliced_rt - med_log) > 3 * mad_log
  ) %>%
  filter(!is_outlier) %>%  # drop the extreme log-RTs
  ungroup() %>%
  # back-transform so your cleaned RTs are on the original scale
  mutate(reaction_time_clean = exp(normaliced_rt)) %>%
  select(-med_log, -mad_log, -is_outlier)

data$with_noise <- factor(data$with_noise)

hist(clean_data$reaction_time)
hist(clean_data$normaliced_rt)
write_csv(clean_data, "data.csv")
