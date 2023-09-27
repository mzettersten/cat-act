library(tidyverse)
library(here)
library(jsonlite)

#### processing functions ####
read_and_combine_data <- function(data_path, column_types=NULL, file_ext = ".csv") {
  filepaths <- list.files(data_path, full.names = TRUE, pattern = file_ext)
  full_dataset <- map(filepaths, ~{read_csv(.x,col_types = column_types)}) %>% 
    bind_rows()
  full_dataset
}

path <- here("GitLab","catact-free-sort","data")

d <- read_and_combine_data(path)

sorting <- d %>%
  filter(!is.na(final_locations))

sorting_long <- sorting %>%
  mutate(final_locations = map(final_locations, ~jsonlite::fromJSON(.x))) %>%
  unnest(final_locations)  


