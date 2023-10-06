library(tidyverse)
library(here)
library(jsonlite)
library(ggimage)
#install_github("YuLab-SMU/ggtree")
library(harrietr) #need to have ggtree installed too, download from github if necessary
library(dendextend)
library(fs)
library(cowplot)

source(here::here("analysis","free-sort","helper.R"))

sort_data_path <- here("data","free-sort","processed","catact-free-sort-average_distances.csv")
dream_data_path <- here("data","free-sort","processed","catact_dreamsim_image_pairwise_distances.csv")
FIGURE_PATH <- here("analysis","free-sort","figures")

sort_distances <- read_csv(sort_data_path) %>%
  mutate(
    stim_category1=stim_category,
    stim_category2=stim_category
  ) %>%
  rename(sort_distance=avg_dist) %>%
  select(-stim_category)

  
dream_distances <- read_csv(dream_data_path) %>%
  mutate(
    item1=tools::file_path_sans_ext(path_file(image_1)),
    item2=tools::file_path_sans_ext(path_file(image_2)),
    stim_category1=path_file(path_dir(image_1)),
    stim_category2=path_file(path_dir(image_2))
  ) %>%
  rename(
    dream_distance=distance
  )

joined_distances <- sort_distances %>%
  left_join(dream_distances)

#plot correlation
#untransformed distances
ggplot(joined_distances,aes(sort_distance,dream_distance))+
  geom_point(alpha=0.5)+
  geom_smooth(method="loess")+
  geom_smooth(method="lm",color="red")+
  theme_cowplot()

#log-transformed sort distances
ggplot(joined_distances,aes(log(sort_distance),dream_distance))+
  geom_point(alpha=0.5)+
  geom_smooth(method="loess")+
  geom_smooth(method="lm",color="red")+
  theme_cowplot()

#untransformed
cor.test(joined_distances$sort_distance,joined_distances$dream_distance)
#transformed sort distance
cor.test(log(joined_distances$sort_distance),joined_distances$dream_distance)


#create hierarchical clusters for dreamsim

#average distance object organized by sorting group
avg_dream_dist <- joined_distances %>%
  mutate(stim_category=stim_category1) %>%
  mutate(avg_dist=dream_distance) %>%
  group_by(stim_category) %>%
  nest() %>%
  mutate(dist_obj = purrr::map(data, long_to_dist)) %>%
  filter(!(stim_category %in% c("practice_1","practice_2")))

#### create overall grouped cluster objects ####
dream_clusters_by_stim <- avg_dream_dist %>%
  mutate(cluster=lapply(dist_obj, function(d) clean_cluster(d))) %>%
  mutate(dend = lapply(cluster, function(clst) clst %>% as.dendrogram()))

#look at a few clustering solutions
dream_clusters_by_stim  %>% filter(stim_category=="stims_ani") %>% pull(dend) %>% pluck(1) %>% plot(main="Animal Category")

#plot all dendrograms
for (stim_cat in unique(dream_clusters_by_stim$stim_category)) {
  print(stim_cat)
  #set up figure
  figure_name <- paste0(stim_cat,"_dendrogram.png")
  figure_path_name <- here(FIGURE_PATH,"dream_plots",figure_name)
  png(figure_path_name) 
  #plot the relevant cluster
  dream_clusters_by_stim  %>% 
    filter(stim_category==stim_cat) %>% 
    pull(dend) %>% 
    pluck(1) %>% 
    plot(main=stim_cat)
  #finish saving the figure
  dev.off()
}

#create hierarchical clusters for sorting
#average distance object organized by sorting group
avg_sort_dist <- sort_distances %>%
  mutate(stim_category=stim_category1) %>%
  mutate(avg_dist=sort_distance) %>%
  group_by(stim_category) %>%
  nest() %>%
  mutate(dist_obj = purrr::map(data, long_to_dist))

#### create overall grouped cluster objects ####
sort_clusters_by_stim <- avg_sort_dist %>%
  mutate(cluster=lapply(dist_obj, function(d) clean_cluster(d))) %>%
  mutate(dend = lapply(cluster, function(clst) clst %>% as.dendrogram()))

#look at tanglegram
dream_clusters_by_stim_dend_ani <- dream_clusters_by_stim  %>% filter(stim_category=="stims_ani") %>% pull(dend) %>% pluck(1) 
sort_clusters_by_stim_dend_ani <- sort_clusters_by_stim  %>% filter(stim_category=="stims_ani") %>% pull(dend) %>% pluck(1) 
dl <- dendlist(dream_clusters_by_stim_dend_ani, sort_clusters_by_stim_dend_ani)
dl %>%
  untangle(method = "random", R = 1000) %>%
  plot(main_left="DreamSim",main_right="Human Sorting",main="Aminals")

#plot all entanglement dendrograms
for (stim_cat in unique(dream_clusters_by_stim$stim_category)) {
  print(stim_cat)
  #set up figure
  figure_name <- paste0(stim_cat,"_dendrogram_entangled_sortvsdream.png")
  figure_path_name <- here(FIGURE_PATH,"dream_plots",figure_name)
  png(figure_path_name) 
  #plot the relevant cluster
  dream_clusters_by_stim_dend <- dream_clusters_by_stim  %>% filter(stim_category==stim_cat) %>% pull(dend) %>% pluck(1) 
  sort_clusters_by_stim_dend <- sort_clusters_by_stim  %>% filter(stim_category==stim_cat) %>% pull(dend) %>% pluck(1) 
  dl <- dendlist(dream_clusters_by_stim_dend, sort_clusters_by_stim_dend)
  dl %>%
    untangle(method = "random", R = 1000) %>%
    plot(main=stim_cat,main_left="DreamSim",main_right="Human Sorting")
  
  #finish saving the figure
  dev.off()
}

