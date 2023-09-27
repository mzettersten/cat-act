library(tidyverse)
library(here)
library(jsonlite)
library(ggimage)

source(here("analysis","free-sort","helper.R"))

data_path <- here("data","free-sort","processed","catact-free-sort-alldata-anonymized.csv")

d <-  read_csv(data_path)

sorting_data <- d %>%
  filter(!is.na(final_locations))

sorting_long <- sorting_data %>%
  mutate(final_locations = map(final_locations, ~jsonlite::fromJSON(.x))) %>%
  unnest(final_locations)  %>%
  mutate(
    image_path = here("experiments","catact-free-sort",src)
  )

## NEST AND PLOT ALL SORTING ARRANGEMENTS BY TRIAL AND SUBJECT
sorting_long_nested_by_trial <- sorting_long %>%
  ungroup() %>%
  #nest sorting long by trial
  select(subject,stim_category,x,y,image_path) %>%
  mutate(
    subject_id=subject,
    stim_id=stim_category
  ) %>%
  group_by(subject, stim_category) %>%
  nest(data = c(subject_id,stim_id,x, y, image_path)) 

sorting_long_nested_by_trial %>%
  #use map to apply plotting function to each trial
  mutate(plot=map(data,~plot_and_save_sort(.x)))

