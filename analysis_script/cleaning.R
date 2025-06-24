
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
data <- list.files(path = folder_path,
                   pattern    = "\\.csv$",
                   full.names = TRUE) %>%
  set_names(~ tools::file_path_sans_ext(basename(.))) %>%
  map_dfr(read_csv,
          .id      = "source_file",
          # force reaction_time to double:
          col_types = cols(
            reaction_time = col_double(),
            .default      = col_guess()
          ))

data <- data %>%
  rename(id = source_file) 

# Cleaning
data <- data %>%
  # Filter only the testing phase
  filter(phase != "training") %>%
  drop_na(reaction_time)

# Log transformation
data$normaliced_rt = log(data$reaction_time)
boxplot(data$normaliced_rt)

# 3. Clean & prepare --------------------------------------------------
data_clean <- data %>%
  # 3a) drop impossible RTs and any NAs
  filter(!is.na(reaction_time),
         reaction_time > 0.1,
         reaction_time < 3.0) %>%
  # 3b) ensure your subject ID and predictor are factors
  mutate(
    id         = factor(id),
    with_noise = factor(with_noise, levels = c(FALSE, TRUE))
  )

# 4. Outlier removal via log–MAD --------------------------------------
data_trim <- data_clean %>%
  mutate(logRT = log(reaction_time)) %>%
  group_by(id) %>%
  filter(abs(logRT - median(logRT)) <= 3 * mad(logRT)) %>%
  ungroup() %>%
  select(-logRT)
data$with_noise <- factor(data$with_noise)

hist(data_trim$reaction_time)
hist(data_trim$normaliced_rt)
write_csv(data_trim, "data.csv")
