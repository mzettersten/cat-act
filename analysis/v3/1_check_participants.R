library(here)
library(tidyverse)
library(jsonlite)
library(tidyjson)
library(rlang)
source("helper.R")

data_path <- here("..","..","data","v3","processed", "catact-v3-alldata.csv")
cloud_path <- here("..","..","data","v3","processed","catact_v3_cloudresearch_submissions.csv")
qualtrics_path <- here("..","..","data","v3","processed","catact_v3_qualtrics_processed.csv")

#### read in data ####
d <- read_csv(data_path)
cloud <- read_csv(cloud_path)
qualtrics <- read_csv(qualtrics_path)

#### handle/ compare to cloudresearch submissions ####
unique_pavlovia_participants <- d %>%
  distinct(workerId,assignmentId,hitId,code)

cloud_submitted <- cloud %>%
  filter(ApprovalStatus!="Not Submitted")

#### comparing participants
setdiff(unique_pavlovia_participants$workerId,cloud_submitted$AmazonIdentifier)
setdiff(cloud_submitted$AmazonIdentifier,unique_pavlovia_participants$workerId)

setdiff(unique_pavlovia_participants$workerId,qualtrics$workerId)
setdiff(qualtrics$workerId,unique_pavlovia_participants$workerId)

#### join
cloud_submitted <- cloud_submitted %>%
  left_join(unique_pavlovia_participants, by=c("AmazonIdentifier"="workerId")) %>%
  mutate(code_correct = case_when(
    `Actual Completion Code`==code ~ 1,
    TRUE ~0
  ))

sum(cloud_submitted$code_correct) #one mismatch but data seems ok

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
test_data_long_path <- here("..","..","data","v3","processed", "catact-v3-test-data-long.csv")
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

write_csv(bonus_participants,here("..","..","data","v3","processed","catact-v3-bonus_participants.csv"))

#### remove bot-like mTurk ids
universal_exclude <- c(
  "p819927", #strange entries for strategy "well","like", "like" (consider not approving HIT)
  "p213195", #nonsensical entries for word meaning
  "p688014", #nonsensical entries for word meaning ("well")
  "p753960", #weird entries for word meaning ("I like it vegetables")
  "p555138", #really weird entry in word meaning ("numerology number")
  "p64838", #odd entries throughout
  "p647510", #strange entries for word meaning (good) - do not approve HIT
  "p558969", #strange entry in word meaning (kindergarten)
  "p770998", #very strange entries for word meaning - do not approve HIT
  "p812996", #very strange entries for word meaning (amazing, good)
  "p115441", #very strange entries for word meaning
  "p767014", #very strange entries for word meaning
  "p137673", #strange responses do not approve HIT
  "p838858", #strange word meaning responses (none, smart)
  "p166078", #very strange responses, do not approve HIT
  "p489104", #googled entry, block going forward
  "p462395", #odd word meaning entries (rabbit)
  "p790605", #weird entries
  "p566001", #weird entries, do not approve HIT
  "p763981", #very odd responses, do not approve HIT
  "p434883", #bizarre entries. do not approve HIT
  "p193133", #bizarre entries ("killed in a terrorist attack")
  "p608088", #bizarre entries
  "p954241", #bizarre entries, do not approve HIT
  "p645217", #bizarre entries (brave, god, god), do not approve HIT
  "p687440", #weird entries
  "p61772", # weird free response entries
  "p230080", #odd entries
  "p722381", #odd entries
  "p713392", #odd entries
  "p607782", #very odd entries
  "p640745", #weird entries
  "p151094", #weird responses, consider blocking
  "p143576", #weird responses, do not approve HIT
  "p604257", #weird, explicit responses
  "p480704", #weird googled responses
  "p406908", #odd responses
  "p329410", #odd responses
  "p71692", #indicated labels as word meaning --> possibly bot-like behavior
  "p992389", #odd, possibly googled and misspelled responses
  "p685856", #strange googled responses
  "p857495" #odd googled word meaning responses
) 
universal_exclude_df <- data.frame(subject=universal_exclude,universal_exclude=1)

mturkids_universal_exclude <- d %>%
  left_join(universal_exclude_df) %>%
  filter(universal_exclude==1) %>%
  distinct(subject,workerId) %>%
  select(-subject)

write_csv(mturkids_universal_exclude,here("..","..","data","v3","processed","catact-v3-universal_exclude_participants.csv"))

          