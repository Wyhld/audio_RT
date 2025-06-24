
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
clean_data <- data %>%
  # Replace long names like "test 1_Categorization_Task_..." with "test_1"
  mutate(id = str_extract(id, "test\\s?\\d+") %>%
           str_replace(" ", "_")) %>%
  
  # Filter only the testing phase
  filter(phase != "training")

clean_data$normaliced_rt = log(clean_data$reaction_time)

hist(clean_data$reaction_time)
hist(clean_data$normaliced_rt)
