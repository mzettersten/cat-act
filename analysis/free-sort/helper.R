library(tidyverse)
library(here)
library(ggimage)

XLIMITS <- c(0,800)
YLIMITS <- c(0,700)
FIGURE_PATH <- here("analysis","free-sort","figures","visualize_sorting")


## Plot the sorting arrangement of a single trial, and store the corresponding image
plot_and_save_sort <- function(sorting_trial_data) {
  #plot the sorting trial
  ggplot(sorting_trial_data, aes(x, y)) + 
    geom_image(aes(image=image_path), size=.15)+
    xlim(0,800)+
    ylim(0,700)
  subject_id <- unique(sorting_trial_data$subject_id)
  stim_category <- unique(sorting_trial_data$stim_id)
  figure_name <- paste0(subject_id,"_",stim_category,".png")
  figure_path_name <- here(FIGURE_PATH,figure_name)
  #save the figure
  ggsave(figure_path_name)
}