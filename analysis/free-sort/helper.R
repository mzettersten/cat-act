library(tidyverse)
library(here)
library(jsonlite)
library(ggimage)
#install_github("YuLab-SMU/ggtree")
library(harrietr) #need to have ggtree installed too, download from github if necessary
library(dendextend)

XLIMITS <- c(0,800)
YLIMITS <- c(0,700)
FIGURE_PATH_SORTING <- here("analysis","free-sort","figures","visualize_sorting")
FIGURE_PATH <- here("analysis","free-sort","figures")


## Plot the sorting arrangement of a single trial, and store the corresponding image
plot_and_save_sort <- function(sorting_trial_data) {
  #plot the sorting trial
  ggplot(sorting_trial_data, aes(x, y)) + 
    geom_image(aes(image=image_path), size=.15)+
    xlim(-50,800)+
    ylim(-50,700)
  subject_id <- unique(sorting_trial_data$subject_id)
  stim_category <- unique(sorting_trial_data$stim_id)
  figure_name <- paste0(subject_id,"_",stim_category,".png")
  figure_path_name <- here(FIGURE_PATH_SORTING,figure_name)
  #save the figure
  ggsave(figure_path_name)
}

library(tidyverse)

#### function for computing distance matrix
get_distance <- function(current_d,normalize_dist=T) {
  
  current_d <- current_d %>%
    tibble::column_to_rownames(var = "image_name_level")
  
  d_dist <- current_d %>%
    dplyr::select(x,y) %>%
    as.matrix() %>%
    dist(diag=T,upper=T)
  
  if (normalize_dist) {
    d_dist <- d_dist/(max(d_dist))
  }
  
  d_dist
}

#### convert long data to dist object ####
long_to_dist <- function(d_long, colnames=c("item1","item2"),dist_name="avg_dist") {
  #add zero distance columns (to avoid some problems when converting to a matrix)
  zero_distance_d <- data.frame(
    col1 = unique(c(pull(d_long[colnames[1]]),pull(d_long[colnames[2]]))),
    col2 = unique(c(pull(d_long[colnames[1]]),pull(d_long[colnames[2]]))), 
    col3 = 0)
  
  colnames(zero_distance_d) <- c(colnames,dist_name)
  
  #add zero distance columns to long data frame
  d_long <- bind_rows(d_long,zero_distance_d)
  
  #convert long data to wide
  dist_wide <- d_long %>%
    select(c(colnames,all_of(dist_name))) %>%
    spread(colnames[1], dist_name) %>%
    #add rownames
    column_to_rownames("item2")
  
  #convert to matrix and then to dist object
  dist <- as.matrix(dist_wide) %>%
    as.dist()
  
  dist
}

# function for creating hierarchical cluster
clean_cluster <- function(d,cur_method="ward.D2") {
  cur_cluster <- d %>%
    hclust(method = cur_method)
  cur_cluster
}
