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
library(ggbeeswarm)
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
  theme_cowplot(font_size=30)+
  theme(axis.title = element_text(face="bold", size=36),
        axis.text.x  = element_text(angle=90, hjust=1,vjust=0.4))
ggsave(here(figure_path,"sampling_choices_exps1_2.pdf"),width=12,height=16)


## Test Plot

subj_test_prop <- test_array_options_clean %>%
  group_by(version,subject,current_category_training_level,current_category_label_level,current_category_kind) %>%
  summarize(
    N_subordinate = sum(test_image_type=="subordinate" & test_image_match_category==1),
    prop_subordinate = sum(test_image_type=="subordinate" & test_image_match_category==1 & is_chosen == 1)/sum(test_image_type=="subordinate" & test_image_match_category==1),
    N_basic = sum(test_image_type=="basic" & test_image_match_category==1),
    prop_basic = sum(test_image_type=="basic" & test_image_match_category==1 & is_chosen == 1)/sum(test_image_type=="basic" & test_image_match_category==1),
    N_superordinate = sum(test_image_type=="superordinate" & test_image_match_category==1),
    prop_superordinate = sum(test_image_type=="superordinate" & test_image_match_category==1 & is_chosen == 1)/sum(test_image_type=="superordinate" & test_image_match_category==1)
  )

subj_test_prop_long <- subj_test_prop %>%
  pivot_longer(N_subordinate:prop_superordinate,names_to=c(".value","choice_type"),names_sep="\\_")

overall_test_prop <- subj_test_prop %>%
  group_by(version,current_category_training_level) %>%
  summarize(
    N=n(),
    subordinate_percent = mean(prop_subordinate),
    basic_percent = mean(prop_basic),
    superordinate_percent = mean(prop_superordinate)
  )

overall_test_prop_long <- subj_test_prop_long %>%
  group_by(version,current_category_training_level,choice_type) %>%
  summarize(
    N=n(),
    avg_prop = mean(prop),
    prop_ci=qt(0.975, N-1)*sd(prop,na.rm=T)/sqrt(N),
    prop_lower_ci=avg_prop-prop_ci,
    prop_upper_ci=avg_prop+prop_ci,
  )
overall_test_prop_long$choice_type_ord <- factor(overall_test_prop_long$choice_type,levels=c("subordinate","basic","superordinate"))
overall_test_prop_long$current_category_training_level_ord <- factor(overall_test_prop_long$current_category_training_level,levels=c("narrow","intermediate","broad"))

p1 <- ggplot(filter(overall_test_prop_long,version==1),aes(choice_type_ord,avg_prop,fill=choice_type_ord))+
  geom_bar(stat="identity")+
  geom_errorbar(aes(ymin=prop_lower_ci,ymax=prop_upper_ci),width=0.1)+
  facet_wrap(~current_category_training_level_ord)+
  theme_cowplot(font_size=20)+
  scale_fill_manual(
    name="Test Choice Type",
    values=c("#d7191c","#fdae61","#abd9e9"))+
  xlab("Test Choice Type")+
  ylab("Average Proportion\nof Test Choices")+
  theme(axis.title = element_text(face="bold", size=24),
        axis.text.x  = element_text(angle=90, hjust=1,vjust=0.4))+
  theme(legend.position="none")
p1
p2 <- ggplot(filter(overall_test_prop_long,version==2),aes(choice_type_ord,avg_prop,fill=choice_type_ord))+
  geom_bar(stat="identity")+
  geom_errorbar(aes(ymin=prop_lower_ci,ymax=prop_upper_ci),width=0.1)+
  facet_wrap(~current_category_training_level_ord)+
  theme_cowplot(font_size=20)+
  scale_fill_manual(
    name="Test Choice Type",
    values=c("#d7191c","#fdae61","#abd9e9"))+
  xlab("Test Choice Type")+
  ylab("Average Proportion\nof Test Choices")+
  theme(axis.title = element_text(face="bold", size=24),
        axis.text.x  = element_text(angle=90, hjust=1,vjust=0.4))+
  theme(legend.position="none")
p2
plot_grid(p1,p2,ncol=1,labels=c("A","B"),label_size=24)
ggsave(here(figure_path,"test_choices_exps1_2.pdf"),width=6,height=12)

## Relationship between Test and Sampling

### longer test representation
subj_test_accuracy_all <- test_array_options_clean %>%
  group_by(version,subject,trial_type,current_category_training_level,current_category_label_level,current_category_kind,final_choice_array,total_number_correct_options_label,total_number_correct_options_training) %>%
  summarize(
    accuracy_training = mean(is_match_to_training, na.rm=TRUE),
    accuracy_label = mean(is_match_to_label,na.rm=TRUE),
    hit_rate_training = mean(hit_training,na.rm=TRUE),
    hit_rate_label = mean(hit_label,na.rm=TRUE),
    false_alarm_rate_training = mean(false_alarm_training,na.rm=TRUE),
    false_alarm_rate_label = mean(false_alarm_label,na.rm=TRUE)
  ) %>%
  mutate(
    hit_rate_training_adj= case_when(
      hit_rate_training==1 ~ 1 - 1/(2*total_number_correct_options_training),
      hit_rate_training==0 ~ 1/(2*total_number_correct_options_training),
      TRUE ~ hit_rate_training
    ),
    hit_rate_label_adj= case_when(
      hit_rate_label==1 ~ 1 - 1/(2*total_number_correct_options_label),
      hit_rate_label==0 ~ 1/(2*total_number_correct_options_label),
      TRUE ~ hit_rate_label
    ),
    false_alarm_rate_training_adj= case_when(
      false_alarm_rate_training==0 ~ 1/(2*total_number_correct_options_training),
      false_alarm_rate_training==1 ~ 1 - 1/(2*total_number_correct_options_training),
      TRUE ~ false_alarm_rate_training
    ),
    false_alarm_rate_label_adj= case_when(
      false_alarm_rate_label==0 ~ 1/(2*total_number_correct_options_label),
      false_alarm_rate_label==1 ~ 1 - 1/(2*total_number_correct_options_label),
      TRUE ~ false_alarm_rate_label
    )
  ) %>%
  mutate(
    dprime_training=qnorm(hit_rate_training_adj) - qnorm(false_alarm_rate_training_adj),
    dprime_label=qnorm(hit_rate_label_adj) - qnorm(false_alarm_rate_label_adj),
    c_training=-.5*(qnorm(hit_rate_training_adj) + qnorm(false_alarm_rate_training_adj)),
    c_label=-.5*(qnorm(hit_rate_label_adj) + qnorm(false_alarm_rate_label_adj)))

subj_test_accuracy_all <- subj_test_accuracy_all %>%
  left_join(sampling_data)

subj_sampling <- sampling_data %>%
  group_by(version,subject) %>%
  summarize(
    mean_consistent=mean(sampling_choice_consistent_b),
    mean_consistent_adj=mean(sampling_choice_consistent_b-chance_consistent),
    mean_consistent_adj_2=mean(sampling_choice_consistent_b-chance_consistent_4afc),
    mean_narrowly_constraining = mean(sampling_choice_narrow_constraining_b),
    mean_narrowly_constraining_adj = mean(sampling_choice_narrow_constraining_b-chance_narrowly_constraining),
    mean_narrowly_constraining_adj_2 = mean(sampling_choice_narrow_constraining_b-chance_narrowly_constraining_4afc),
    mean_outside_category=mean(sampled_category_level_kind_info=="outside_category"))

subj_test_accuracy_all <- subj_test_accuracy_all %>%
  left_join(subj_sampling)

subj_test_accuracy_all_summarized <- subj_test_accuracy_all %>%
  group_by(version,subject,mean_consistent,mean_narrowly_constraining) %>%
  summarize(
    avg_dprime = mean(dprime_label)
  )

## Option 1: Plotting each individual test trial response

p1 <- ggplot(filter(subj_test_accuracy_all,version==1),aes(mean_consistent,dprime_label))+
  geom_jitter(width=0.05,alpha=0.5)+
  geom_smooth(method="lm",color="#f46d43")+
  theme_cowplot(font_size=24)+
  xlab("Average Proportion\n Confirming Choices")+
  ylab("d prime")+
  scale_y_continuous(breaks=c(-2,-1,0,1,2,3,4),limits=c(-2,4))+
  theme(axis.title = element_text(face="bold", size=30))+
  ggtitle("Experiment 1") +
  theme(plot.title = element_text(hjust = 0.5, face="bold",size=28))

p2 <- ggplot(filter(subj_test_accuracy_all,version==1),aes(mean_narrowly_constraining,dprime_label))+
  geom_jitter(width=0.05,alpha=0.5)+
  geom_smooth(method="lm",color="#f46d43")+
  theme_cowplot(font_size=24)+
  xlab("Average Proportion\n Constraining Choices")+
  ylab("d prime")+
  scale_y_continuous(breaks=c(-2,-1,0,1,2,3,4),limits=c(-2,4))+
  theme(axis.title = element_text(face="bold", size=30))+
  ggtitle("Experiment 1") +
  theme(plot.title = element_text(hjust = 0.5, face="bold",size=28))

p3 <- ggplot(filter(subj_test_accuracy_all,version==2),aes(mean_consistent,dprime_label))+
  geom_jitter(width=0.05,alpha=0.5)+
  geom_smooth(method="lm",color="#f46d43")+
  theme_cowplot(font_size=24)+
  xlab("Average Proportion\n Confirming Choices")+
  ylab("d prime")+
  scale_y_continuous(breaks=c(-2,-1,0,1,2,3,4),limits=c(-2,4))+
  theme(axis.title = element_text(face="bold", size=30))+
  ggtitle("Experiment 2") +
  theme(plot.title = element_text(hjust = 0.5, face="bold",size=28))

p4 <- ggplot(filter(subj_test_accuracy_all,version==2),aes(mean_narrowly_constraining,dprime_label))+
  geom_jitter(width=0.05,alpha=0.5)+
  geom_smooth(method="lm",color="#f46d43")+
  theme_cowplot(font_size=24)+
  xlab("Average Proportion\n Constraining Choices")+
  ylab("d prime")+
  scale_y_continuous(breaks=c(-2,-1,0,1,2,3,4),limits=c(-2,4))+
  theme(axis.title = element_text(face="bold", size=30))+
  ggtitle("Experiment 2") +
  theme(plot.title = element_text(hjust = 0.5, face="bold",size=28))

plot_grid(p1,p3,p2,p4,ncol=2,labels=c("A","B","C","D"),label_size=28)
ggsave(here(figure_path,"sampling_test_exp12.pdf"),width=12,height=12)

## Option 2: Summarizing across test trials for each subject

p1 <- ggplot(filter(subj_test_accuracy_all_summarized,version==1),aes(mean_consistent,avg_dprime))+
  geom_jitter(width=0.05,alpha=0.5)+
  geom_smooth(method="lm",color="#f46d43")+
  theme_cowplot(font_size=24)+
  xlab("Average Proportion\n Confirming Choices")+
  ylab("d prime")+
  scale_y_continuous(breaks=c(-2,-1,0,1,2,3,4),limits=c(-0.4,3))+
  theme(axis.title = element_text(face="bold", size=30))+
  ggtitle("Experiment 1") +
  theme(plot.title = element_text(hjust = 0.5, face="bold",size=28))

p2 <- ggplot(filter(subj_test_accuracy_all_summarized,version==1),aes(mean_narrowly_constraining,avg_dprime))+
  geom_jitter(width=0.05,alpha=0.5)+
  geom_smooth(method="lm",color="#f46d43")+
  theme_cowplot(font_size=24)+
  xlab("Average Proportion\n Constraining Choices")+
  ylab("d prime")+
  scale_y_continuous(breaks=c(-2,-1,0,1,2,3,4),limits=c(-0.4,3))+
  theme(axis.title = element_text(face="bold", size=30))+
  ggtitle("Experiment 1") +
  theme(plot.title = element_text(hjust = 0.5, face="bold",size=28))

p3 <- ggplot(filter(subj_test_accuracy_all_summarized,version==2),aes(mean_consistent,avg_dprime))+
  geom_jitter(width=0.05,alpha=0.5)+
  geom_smooth(method="lm",color="#f46d43")+
  theme_cowplot(font_size=24)+
  xlab("Average Proportion\n Confirming Choices")+
  ylab("d prime")+
  scale_y_continuous(breaks=c(-2,-1,0,1,2,3,4),limits=c(-0.4,3))+
  theme(axis.title = element_text(face="bold", size=30))+
  ggtitle("Experiment 2") +
  theme(plot.title = element_text(hjust = 0.5, face="bold",size=28))

p4 <- ggplot(filter(subj_test_accuracy_all_summarized,version==2),aes(mean_narrowly_constraining,avg_dprime))+
  geom_jitter(width=0.05,alpha=0.5)+
  geom_smooth(method="lm",color="#f46d43")+
  theme_cowplot(font_size=24)+
  xlab("Average Proportion\n Constraining Choices")+
  ylab("d prime")+
  scale_y_continuous(breaks=c(-2,-1,0,1,2,3,4),limits=c(-0.4,3))+
  theme(axis.title = element_text(face="bold", size=30))+
  ggtitle("Experiment 2") +
  theme(plot.title = element_text(hjust = 0.5, face="bold",size=28))

plot_grid(p1,p3,p2,p4,ncol=2,labels=c("A","B","C","D"),label_size=28)
ggsave(here(figure_path,"sampling_test_summarized_exp12.pdf"),width=12,height=12)
