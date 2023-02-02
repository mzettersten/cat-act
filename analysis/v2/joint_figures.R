library(here)
library(tidyverse)
library(ggplot2)
library(viridisLite)
library(lme4)
library(ggstance)
library(cowplot)
library(AICcmodavg)
library(RColorBrewer)
library(jsonlite)
library(tidyjson)
library(rlang)
library(car)
source("helper.R")

# Read in data
data_path_v1 <- here("..","..","data","v1","processed", "catact-v1-alldata-processed.csv")
sampling_data_path_v1 <- here("..","..","data","v1","processed", "catact-v1-sampling-data.csv")
test_data_path_v1 <- here("..","..","data","v1","processed", "catact-v1-test-data.csv")
test_data_long_path_v1 <- here("..","..","data","v1","processed", "catact-v1-test-data-long.csv")

data_path_v2 <- here("..","..","data","v2","processed", "catact-v2-alldata-processed.csv")
sampling_data_path_v2 <- here("..","..","data","v2","processed", "catact-v2-sampling-data.csv")
test_data_path_v2 <- here("..","..","data","v2","processed", "catact-v2-test-data.csv")
test_data_long_path_v2 <- here("..","..","data","v2","processed", "catact-v2-test-data-long.csv")
figure_path <- here("figures")

d_v1 <- read_csv(data_path_v1) %>%
  mutate(version=1)
d_v2 <- read_csv(data_path_v2) %>%
  mutate(version=2)
d <- d_v1 %>%
  bind_rows(d_v2)

sampling_data_v1 <- read_csv(sampling_data_path_v1) %>%
  mutate(version=1)
sampling_data_v2 <- read_csv(sampling_data_path_v2) %>%
  mutate(version=2)
sampling_data <- sampling_data_v1 %>%
  bind_rows(sampling_data_v2)

test_array_clean_v1 <- read_csv(test_data_path_v1) %>%
  mutate(version=1)
test_array_clean_v2 <- read_csv(test_data_path_v2) %>%
  mutate(version=2)
test_array_clean <- test_array_clean_v1 %>%
  bind_rows(test_array_clean_v2)
  
test_array_options_clean_v1 <- read_csv(test_data_long_path_v1) %>%
  mutate(version = 1)
test_array_options_clean_v2 <- read_csv(test_data_long_path_v2) %>%
  mutate(version = 2)
test_array_options_clean <- test_array_options_clean_v1 %>%
  bind_rows(test_array_options_clean_v2)

## handle exclusions

d <- d %>%
  filter(exclude_participant==0)
sampling_data <- sampling_data  %>%
  filter(exclude_participant==0) %>%
  filter(levenshtein_distance<2)
test_array_clean <- test_array_clean %>%
  filter(exclude_participant==0) %>%
  filter(levenshtein_distance<2)
test_array_options_clean <- test_array_options_clean %>%
  filter(exclude_participant==0) %>%
  filter(levenshtein_distance<2)

## Sampling Plot
sampling_data$sampled_category_level_kind_info_ord <- factor(sampling_data$sampled_category_level_kind_info,
                                                             levels=c("sub","bas","sup","outside_category"),
                                                             labels=c("subordinate","basic","superordinate","outside category"))
sampling_data$current_category_training_level_ord <- factor(sampling_data$current_category_training_level,levels=c("narrow","intermediate","broad"))
sampling_data <- sampling_data %>%
  mutate(version_name = ifelse(version==1,"Experiment 1","Experiment 2"))

ggplot(sampling_data,aes(current_category_training_level_ord,fill=sampled_category_level_kind_info_ord))+
  geom_bar(position="fill")+
  scale_fill_brewer(name="Sampling Choice Type",palette="RdYlBu")+
  xlab("Training Condition")+
  ylab("Proportion of Sampling Choices")+
  facet_wrap(~version_name)+
  theme_cowplot(font_size=20)+
  theme(axis.title = element_text(face="bold", size=24),
        axis.text.x  = element_text(angle=90, hjust=1,vjust=0.4))
ggsave(here(figure_path,"sampling_choices_exps1_2.pdf"))
