library(tidyverse)
library(here)
library(jsonlite)
library(ggimage)
#install_github("YuLab-SMU/ggtree")
library(harrietr) #need to have ggtree installed too, download from github if necessary

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
  ) %>%
  mutate(
    image_name=str_replace(src,"images/",""),
    image_name_minus_ext=str_replace(image_name,".jpg","")
  ) %>%
  separate(
    image_name_minus_ext,into=c("category","image_name_level"),sep="/",remove=FALSE
  ) %>%
  mutate(
    image_name_level = case_when(
    is.na(image_name_level) ~ image_name_minus_ext,
    TRUE ~ image_name_level
  )) %>%
  select(-category)

#tabulate category responses
sorting_long %>%
  distinct(subject,stim_category) %>%
  group_by(stim_category) %>%
  count()

## NEST AND PLOT ALL SORTING ARRANGEMENTS BY TRIAL AND SUBJECT
sorting_long_nested_by_trial <- sorting_long %>%
  ungroup() %>%
  #nest sorting long by trial
  select(subject,stim_category,x,y,image_path,image_name,image_name_minus_ext,image_name_level) %>%
  mutate(
    subject_id=subject,
    stim_id=stim_category
  ) %>%
  group_by(subject, stim_category) %>%
  nest(data = c(subject_id,stim_id,x, y, image_path,image_name,image_name_minus_ext,image_name_level)) 

sorting_long_nested_by_trial %>%
  #use map to apply plotting function to each trial
  mutate(plot=map(data,~plot_and_save_sort(.x)))

## Compute distance objects ##
# -each participant has scaled distance matrix (0 to 1)
#within each participant divide by the maximum
# -average across all participants on the scaled values
#doing this by sort

#create overall data frame containing (nested) distance objects for each participant
subj_dist <- sorting_long_nested_by_trial %>%
  mutate(dist_object = map(data, get_distance)) %>%
  mutate(dist_matrix = map(dist_object, as.matrix)) %>%
  mutate(dist_long= map(dist_matrix,melt_dist)) %>%
  select(-data)

#create long dataframe with pairwise distances (normalized)
subj_dist_long <-  subj_dist %>%
  select(-dist_object,-dist_matrix) %>%
  unnest(cols = c(dist_long)) %>%
  rename(item1=iso1,item2=iso2) %>%
  mutate(items = paste(pmin(item1, item2), #alphabetically order
                       pmax(item1, item2), sep= "-")) %>%
  select(-item1,-item2) %>%
  separate(items, into=c("item1","item2"),sep="-",remove=F) %>%
  ungroup()

#Average across subjects
#average across all distances
avg_dist_long <- subj_dist_long %>%
  group_by(stim_category,item1,item2) %>%
  summarize(avg_dist=mean(dist)) %>%
  ungroup() %>%
  mutate(stim_category=as.character(stim_category),item1=as.character(item1),item2=as.character(item2))

#average distance object organized by sorting group
avg_dist <- avg_dist_long %>%
  group_by(stim_category) %>%
  nest() %>%
  mutate(dist_obj = purrr::map(data, long_to_dist))

#### create overall grouped cluster objects ####
clusters_by_stim <- avg_dist %>%
  mutate(cluster=lapply(dist_obj, function(d) clean_cluster(d))) %>%
  mutate(dend = lapply(cluster, function(clst) clst %>% as.dendrogram()))

#look at one clustering solution
clusters_by_stim  %>% filter(stim_category=="stims_ani") %>% pull(dend) %>% pluck(1) %>% plot(main="Animal Category")
clusters_by_stim  %>% filter(stim_category=="stims_boa") %>% pull(dend) %>% pluck(1) %>% plot(main="Boat Category")
clusters_by_stim  %>% filter(stim_category=="stims_spo") %>% pull(dend) %>% pluck(1) %>% plot(main="Sports Category")
clusters_by_stim  %>% filter(stim_category=="stims_mus") %>% pull(dend) %>% pluck(1) %>% plot(main="Music Category")
