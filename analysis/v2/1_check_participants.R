library(here)
library(tidyverse)
library(jsonlite)
library(tidyjson)
library(rlang)
source("helper.R")

data_path <- here("..","..","data","v2","processed", "catact-v2-alldata.csv")
cloud_path <- here("..","..","data","v2","processed","cat_v2_cloudresearch_submissions.csv")
qualtrics_path <- here("..","..","data","v2","processed","CatAct V2_February 6, 2023_09.42_processed.csv")

#### read in data ####
d <- read_csv(data_path)
cloud <- read_csv(cloud_path)
qualtrics <- read_csv(qualtrics_path)

#### handle/ compare to cloudresearch submissions ####
unique_pavlovia_participants <- d %>%
  distinct(workerId,assignmentId,hitId,code)

cloud_submitted <- cloud %>%
  filter(ApprovalStatus!="Not Submitted" & ApprovalStatus!="Submitted To CloudResearch but not Amazon")

#### comparing participants
setdiff(unique_pavlovia_participants$workerId,cloud_submitted$AmazonIdentifier)
setdiff(cloud_submitted$AmazonIdentifier,unique_pavlovia_participants$workerId)

setdiff(unique_pavlovia_participants$workerId,qualtrics$workerId)
setdiff(qualtrics$workerId,unique_pavlovia_participants$workerId)

#### join
cloud_submitted <- cloud_submitted %>%
  left_join(unique_pavlovia_participants, by=c("AmazonIdentifier"="workerId"))

sum(cloud_submitted$`Actual Completion Code`==cloud_submitted$code,na.rm=TRUE)


#### counterbalancing check
condition_assignment <- d %>%
  filter(!is.na(current_category_kind)) %>%
  distinct(subject,n_cat_level,i_cat_level,b_cat_level,catk_n,catk_i,catk_b) %>%
  group_by(n_cat_level,i_cat_level,b_cat_level,catk_n,catk_i,catk_b) %>%
  summarize(
    n=n()
  )

condition_assignment %>%
  group_by(n_cat_level,i_cat_level,b_cat_level) %>%
  summarize(
    total_n=sum(n)
  )

condition_assignment %>%
  group_by(catk_n,catk_i,catk_b) %>%
  summarize(
    total_n=sum(n)
  )

### bonusing
#only run if raw/ deanonymized data is available
#### note: first run 2_processing.R to get exclusions
workerId_assignment <- d %>%
  distinct(workerId,subject)

## compute test performance
test_data_long_path <- here("..","..","data","v2","processed", "catact-v2-test-data-long.csv")
test_array_options_clean <- read_csv(test_data_long_path)
test_array_options_clean <- test_array_options_clean %>%
  filter(exclude_participant==0) %>%
  filter(levenshtein_distance<2) %>%
  left_join(workerId_assignment)
subj_test_accuracy_all <- test_array_options_clean %>%
  left_join(select(d,workerId,subject,narrow_category_label_level,intermediate_category_label_level,broad_category_label_level)) %>%
  group_by(workerId,subject,narrow_category_label_level,intermediate_category_label_level,broad_category_label_level,trial_type,current_category_training_level,current_category_label_level,current_category_kind,final_choice_array,total_number_correct_options_label,total_number_correct_options_training) %>%
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

overall_subj_accuracy <- subj_test_accuracy_all %>%
  ungroup() %>%
  group_by(workerId,subject,narrow_category_label_level,intermediate_category_label_level,broad_category_label_level) %>%
  summarize(
    N=n(),
    average_dprime_training=mean(dprime_training),
    average_dprime_label=mean(dprime_label)
  ) %>%
  unite(col="assigned_condition_combo",narrow_category_label_level,intermediate_category_label_level,broad_category_label_level,remove=FALSE)

subjects_top <- overall_subj_accuracy  %>% 
  filter(N==3) %>%
  group_by(assigned_condition_combo) %>%
  select(workerId,subject,assigned_condition_combo,average_dprime_label,average_dprime_training) %>%
  slice_max(average_dprime_label,n = 3) %>%
  mutate(bonus=1)

overall_subj_accuracy <- overall_subj_accuracy %>%
  left_join(subjects_top)
ggplot(filter(overall_subj_accuracy,N==3),aes(average_dprime_label,average_dprime_training,color=as.factor(bonus))) +
  geom_jitter(width=0.01,height=0.01)#+
 # facet_wrap(~assigned_condition_combo)

bonus_participants <- subjects_top %>%
  ungroup() %>%
  distinct(workerId)

write_csv(bonus_participants,here("..","..","data","v2","processed","catact-v2-bonus_participants.csv"))

#### remove bot-like mTurk ids
universal_exclude <- c("p1740",  #bot entries for word_meaning (googled entries)
                       "p474744", #bot entries for word_meaning (googled entries) 
                       "p600079", #bot entries for word_meaning (googled entries) 
                       "p218152", #bot-like entries for word_meaning (appears to use the alternate label)
                       "p602", #nonsensical entries for word_meaning
                       "p782790", #nonsensical entries for word_meaning
                       "p889922" #nonsensical entries for word_meaning
                       )
universal_exclude_df <- data.frame(subject=universal_exclude,universal_exclude=1)

mturkids_universal_exclude <- d %>%
  left_join(universal_exclude_df) %>%
  filter(universal_exclude==1) %>%
  distinct(subject,workerId) %>%
  select(-subject)

write_csv(mturkids_universal_exclude,here("..","..","data","v2","processed","catact-v2-universal_exclude_participants.csv"))

          