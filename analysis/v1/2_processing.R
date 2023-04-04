library(here)
library(tidyverse)
library(jsonlite)
library(tidyjson)
library(rlang)
library(stringdist)
source("helper.R")

data_path <- here("..","..","data","v1","processed", "catact-v1-alldata-anonymized.csv")
write_path <- here("..","..","data","v1","processed")

#### read in data ####
d <- read_csv(data_path)

#### process survey/ nested responses ####
#unnesting json
survey_responses <- d %>% 
  filter(trial_type %in% c("survey-html-form","survey-text","survey-multi-choice","survey-multi-select")) %>%
  select(subject,trial_type,current_category_training_level,current_category_kind,response) %>%
  mutate(json = map(response, ~ fromJSON(.) %>% as.data.frame())) %>% 
  unnest(json) %>%
  group_by(subject) %>%
  fill(age,gender,country,language,other_languages,race,education,strategy,choice_strategy,comments,.direction = "downup") %>%
  select(-response,-trial_type) %>%
  filter(!is.na(current_category_training_level)) %>%
  fill(name_check,.direction = "down") %>%
  fill(word_meaning,.direction = "up") %>%
  distinct()

#write the strategy data frame
strategy_responses_only <- survey_responses %>%
  select(subject,strategy,choice_strategy,comments) %>%
  distinct()
write_csv(strategy_responses_only,here(write_path,"catact-v1-strategy-responses.csv"))

d <- d %>%
  left_join(survey_responses)

#### handle exclusions ####

manage_exclusion_d <- d %>%
  filter(!is.na(current_category_kind)) %>%
  distinct(subject,
           current_category_kind,
           current_category_training_level, 
           current_training_label,
           name_check,
           word_meaning,
           age,
           gender,
           country,
           language,
           other_languages,
           race,
           education,
           strategy,
           choice_strategy,
           comments)

#exclusion critera
manage_exclusion_d %>%
  select(subject,
         current_category_kind,
         current_category_training_level, 
         current_training_label,
         name_check,
         word_meaning,
         strategy,
         choice_strategy,
         comments) %>%
  View()
  
#1. inspect visually for obvious bot-like responses and/ or gibberish
# strategy/ choices/ comments: some likely non-L1 English participants, but no obvious bot-like/ gibberish responses
# word meaning: some definite strangeness here, marking a few for exclusion
exclude_open_responses <- c(
  "p665337",  #very odd word_meaning responses
  "p753363",   #very odd word_meaning responses
  "p910597",    #very odd word_meaning responses
  "p45411", #wildly off word_meaning responses (onion, dogs for the vehicle category)
  "p563154" #wildly off word_meaning responses (playschool for animal category)
) 

#2. investigate name check responses
incorrect_name_check_d <- manage_exclusion_d %>%
  mutate(name_check_edited = trimws(tolower(name_check))) %>%
  mutate(
    levenshtein_distance = stringdist(current_training_label,name_check_edited)
  ) %>%
  filter(levenshtein_distance>1)

summarize_incorrect_name_check_d <- incorrect_name_check_d %>%
  group_by(subject) %>%
  summarize(n=n(),levenshtein_distance = mean(levenshtein_distance))

exclude_fail_name_check <- summarize_incorrect_name_check_d %>%
  filter(n>1) %>%
  pull(subject)

#3. check sampling and test response locations
##sampling
sampling_locations <- d %>%
  filter(trial_type=="html-button-response-cols") %>%
  select(subject,trial_type,response) 
#number of selections by index/ location
sampling_location_num <- sampling_locations %>%
  group_by(subject,response) %>%
  summarize(n=n())
exclude_sampling_location <- sampling_location_num %>%
  filter(n==3) %>%
  pull(subject)
##test
test_locations <- d %>%
  filter(trial_type=="html-button-response-catact") %>%
  select(subject,trial_type,selection_index)
test_location_num <- test_locations %>%
  group_by(subject,selection_index) %>%
  summarize(n=n())
exclude_test_location <- test_location_num %>%
  filter(n==3) %>%
  pull(subject)

exclusions <- unique(c(exclude_open_responses,exclude_fail_name_check,exclude_sampling_location,exclude_test_location))

## add participant-level indicator for exclusions to dataset
d <- d %>%
  mutate(
    exclude_participant = ifelse(subject %in% exclusions,1,0)
  )

## recheck condition assignments
#### counterbalancing check
condition_assignment <- d %>%
  filter(exclude_participant==0) %>% #after participant level exclusions
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

#### add hypernym category ####
temp_sampling_images <- d %>%
  filter(trial_type == "html-button-response-catact") %>%
  select(subject,current_training_label,current_category_label_level, current_category_kind,current_category_training_level,shuffled_sampling_images,sampling_image_words) %>%
  mutate(image_array = map(shuffled_sampling_images, ~ convert_array(.,column_name="image_name"))) %>%
  unnest(image_array) 

temp_sampling_labels <- d %>%
  filter(trial_type == "html-button-response-catact") %>%
  select(subject,current_training_label,current_category_label_level, current_category_kind,current_category_training_level,shuffled_sampling_images,sampling_image_words) %>%
  mutate(label_array = map(sampling_image_words, ~ convert_array(.,column_name="image_label"))) %>%
  unnest(label_array)

sampling_assignment_long <- temp_sampling_images %>%
  left_join(temp_sampling_labels) %>%
  mutate(
    image_category  = case_when(
      str_detect(image_name,"ani") ~ "animals",
      str_detect(image_name,"veg") ~ "vegetables",
      str_detect(image_name,"veh") ~ "vehicles",
    )
  )

hypernym_categories <- sampling_assignment_long %>%
  filter(current_category_label_level=="hypernym") %>%
  mutate(
    hypernym_category = case_when(
      current_training_label == image_label &
        image_category != current_category_kind ~ image_category
    )
  ) %>%
  filter(!is.na(hypernym_category)) %>%
  distinct(subject,current_training_label,current_category_label_level, current_category_kind,current_category_training_level,hypernym_category)

d <- d %>%
  left_join(hypernym_categories) %>%
  relocate(hypernym_category,.after = current_category_kind)

#### process sampling data ####
# process sampled image
d <- d %>%
  mutate(
    sampled_imagename = str_remove(sampled_image,"stims/"),
    sampled_imagelabel = str_remove(sampled_imagename,".jpg")
  ) %>%
  rowwise() %>%
  mutate(
    sampled_category_kind_short = unlist(str_split(sampled_imagelabel,"_"))[1],
    sampled_category_level = str_replace_all(unlist(str_split(sampled_imagelabel,"_"))[3], "[:digit:]","")
  ) %>%
  mutate(
    sampled_category_kind  = case_when(
      sampled_category_kind_short == "ani" ~ "animals",
      sampled_category_kind_short == "veg" ~ "vegetables",
      sampled_category_kind_short == "veh" ~ "vehicles",
    )
  ) %>%
  mutate(
    within_category_sample = ifelse(sampled_category_kind == current_category_kind,1,0),
    within_category_sample_f =  ifelse(sampled_category_kind == current_category_kind,"within-category","other-category"),
  ) %>%
  mutate(
    sampled_category_level_kind_info=ifelse(within_category_sample==0,"outside_category",sampled_category_level)
  )

sampling_data <- d %>%
  filter(trial_type == "html-button-response-catact") %>%
  select(subject,exclude_participant,current_training_images,current_training_label,name_check,shuffled_sampling_images,current_category_label_level, current_category_kind,current_category_training_level,sampled_image, sampled_label,sampled_imagename,sampled_imagelabel,sampled_category_kind_short,sampled_category_kind,sampled_category_level,within_category_sample,within_category_sample_f,sampled_category_level_kind_info)

#categorizing choice types
sampling_data <- sampling_data %>%
  mutate(
    sampling_choice_consistent = case_when(
      current_category_training_level == "narrow" & sampled_category_level_kind_info == "sub" ~ "consistent",
      current_category_training_level == "intermediate" & sampled_category_level_kind_info == "sub" ~ "consistent",
      current_category_training_level == "intermediate" & sampled_category_level_kind_info == "bas" ~ "consistent",
      current_category_training_level == "broad" & sampled_category_level_kind_info == "sub" ~ "consistent",
      current_category_training_level == "broad" & sampled_category_level_kind_info == "bas" ~ "consistent",
      current_category_training_level == "broad" & sampled_category_level_kind_info == "sup" ~ "consistent",
      TRUE ~ "inconsistent"
    ),
    sampling_choice_narrowly_constraining = case_when(
      current_category_training_level == "narrow" & sampled_category_level_kind_info == "bas" ~ "constraining",
      current_category_training_level == "intermediate" & sampled_category_level_kind_info == "sup" ~ "constraining",
      current_category_training_level == "broad" & sampled_category_level_kind_info == "outside_category" ~ "constraining",
      TRUE ~ sampling_choice_consistent
    )
  ) %>%
  #add levenshtein distance
  mutate(name_check_edited = trimws(tolower(name_check))) %>%
  mutate(
    levenshtein_distance = stringdist(current_training_label,name_check_edited)
  )

#adding chance levels
sampling_data <- sampling_data %>%
  mutate(
    chance_consistent = case_when(
      current_category_training_level == "narrow" ~ 1/9,
      current_category_training_level == "intermediate" ~ 2/9,
      current_category_training_level == "broad" ~ 3/9,
    ),
    chance_consistent_4afc = case_when(
      current_category_training_level == "narrow" ~ 1/4,
      current_category_training_level == "intermediate" ~ 2/4,
      current_category_training_level == "broad" ~ 3/4,
    ),
    chance_narrowly_constraining = case_when(
      current_category_training_level == "narrow" ~ 1/9,
      current_category_training_level == "intermediate" ~ 1/9,
      current_category_training_level == "broad" ~ 6/9,
    ),
    chance_narrowly_constraining_4afc = case_when(
      current_category_training_level == "narrow" ~ 1/4,
      current_category_training_level == "intermediate" ~ 1/4,
      current_category_training_level == "broad" ~ 1/4,
    )
  ) %>%
  mutate(
    sampling_choice_consistent_b = ifelse(sampling_choice_consistent=="consistent",1,0),
    sampling_choice_narrow_constraining_b = ifelse(sampling_choice_narrowly_constraining=="constraining",1,0),
  )

# write sampling data
write_csv(sampling_data,here(write_path,"catact-v1-sampling-data.csv"))

# representing sampling in long format with all image options
sampling_data_long <- sampling_data %>%
  mutate(sampling_options = map(shuffled_sampling_images, ~ convert_array(.,column_name="sampling_image"))) %>%
  unnest(sampling_options) 

sampling_data_long <- sampling_data_long %>%
  rowwise() %>%
  mutate(
    is_chosen = case_when(
      sampled_image == sampling_image ~ 1,
      TRUE ~ 0
    )
  ) %>%
  mutate(
    sampling_image_type = case_when(
      str_detect(sampling_image,"sup") ~ "superordinate",
      str_detect(sampling_image,"bas") ~ "basic",
      str_detect(sampling_image,"sub") ~ "subordinate"
    )
  ) %>%
  mutate(
    sampling_image_category = case_when(
      str_detect(sampling_image,"ani") ~ "animals",
      str_detect(sampling_image,"veg") ~ "vegetables",
      str_detect(sampling_image,"veh") ~ "vehicles"
    )
  )


#### test data ####
test_array <- d %>% 
  filter(trial_type == "html-button-response-catact") %>%
  select(subject,exclude_participant,trial_type,current_category_training_level,current_category_label_level,current_category_kind,hypernym_category,final_choice_array) %>%
  mutate(choices = map(final_choice_array, ~ convert_array(.,column_name="test_choice"))) %>%
  unnest(choices) 

test_array_clean <- test_array %>%
  mutate(
    test_choice_type = case_when(
      str_detect(test_choice,"sup") ~ "superordinate",
      str_detect(test_choice,"bas") ~ "basic",
      str_detect(test_choice,"sub") ~ "subordinate"
    )
  ) %>%
  mutate(
    test_choice_category = case_when(
      str_detect(test_choice,"ani") ~ "animals",
      str_detect(test_choice,"veg") ~ "vegetables",
      str_detect(test_choice,"veh") ~ "vehicles"
    )
  ) %>%
  mutate(
    test_choice_match_category = ifelse(test_choice_category == current_category_kind,1,0),
    test_choice_match_ground_truth_category = case_when(
      current_category_label_level == "hypernym" & test_choice_category == hypernym_category ~ 1,
      test_choice_category == current_category_kind ~ 1,
      TRUE ~ 0
    )
  ) %>%
  mutate(
    test_choice_type_training_consistent = case_when(
      current_category_training_level == "narrow" &  test_choice_type %in% c("subordinate") & test_choice_match_category == 1 ~ 1,
      current_category_training_level == "intermediate" &  test_choice_type %in% c("subordinate","basic") & test_choice_match_category == 1 ~ 1,
      current_category_training_level == "broad" &  test_choice_type %in% c("subordinate","basic","superordinate")& test_choice_match_category == 1 ~ 1,
      TRUE ~ 0
    )
  ) %>%
  mutate(
    test_choice_type_label_consistent = case_when(
      current_category_label_level == "narrow" &  test_choice_type %in% c("subordinate") & test_choice_match_category == 1 ~ 1,
      current_category_label_level == "intermediate" &  test_choice_type %in% c("subordinate","basic") & test_choice_match_category == 1 ~ 1,
      current_category_label_level == "broad" & test_choice_match_category == 1 ~ 1,
      current_category_label_level == "hypernym" &  test_choice_match_ground_truth_category == 1 ~ 1,
      TRUE ~ 0
    )
  ) %>%
  mutate(
    total_number_correct_options = case_when(
      current_category_label_level == "narrow" ~ 2,
      current_category_label_level == "intermediate" ~ 4,
      current_category_label_level == "broad" ~ 8,
      current_category_label_level == "hypernym" ~ 16
    )
  )

#join with sampling data
test_array_clean <- test_array_clean %>%
  left_join(sampling_data)

# write test data (shorter representation)
write_csv(test_array_clean,here(write_path,"catact-v1-test-data.csv"))


#### test data - representing all images in long format ####
test_array_options <- d %>% 
  filter(trial_type == "html-button-response-catact") %>%
  select(subject,exclude_participant,trial_type,current_category_training_level,current_category_label_level,current_category_kind,hypernym_category,shuffled_test_images,final_choice_array) %>%
  mutate(test_options = map(shuffled_test_images, ~ convert_array(.,column_name="test_image"))) %>%
  unnest(test_options) 

test_array_options <- test_array_options %>%
  rowwise() %>%
  mutate(
    is_chosen = case_when(
      str_detect(final_choice_array,test_image) ~ 1,
      TRUE ~ 0
    )
  )

test_array_options_clean <- test_array_options %>%
  mutate(
    test_image_type = case_when(
      str_detect(test_image,"sup") ~ "superordinate",
      str_detect(test_image,"bas") ~ "basic",
      str_detect(test_image,"sub") ~ "subordinate"
    )
  ) %>%
  mutate(
    test_image_category = case_when(
      str_detect(test_image,"ani") ~ "animals",
      str_detect(test_image,"veg") ~ "vegetables",
      str_detect(test_image,"veh") ~ "vehicles"
    )
  ) %>%
  mutate(
    test_image_match_category = ifelse(test_image_category == current_category_kind,1,0),
    test_image_match_ground_truth_category = case_when(
      current_category_label_level == "hypernym" & test_image_category == hypernym_category ~ 1,
      test_image_category == current_category_kind ~ 1,
      TRUE ~ 0
    )
  ) %>%
  mutate(
    test_image_type_training_consistent = case_when(
      current_category_training_level == "narrow" &  test_image_type %in% c("subordinate") & test_image_match_category == 1 ~ 1,
      current_category_training_level == "intermediate" &  test_image_type %in% c("subordinate","basic") & test_image_match_category == 1 ~ 1,
      current_category_training_level == "broad" &  test_image_type %in% c("subordinate","basic","superordinate")& test_image_match_category == 1 ~ 1,
      TRUE ~ 0
    )
  ) %>%
  mutate(
    test_image_type_label_consistent = case_when(
      current_category_label_level == "narrow" &  test_image_type %in% c("subordinate") & test_image_match_category == 1 ~ 1,
      current_category_label_level == "intermediate" &  test_image_type %in% c("subordinate","basic") & test_image_match_category == 1 ~ 1,
      current_category_label_level == "broad" & test_image_match_category == 1 ~ 1,
      current_category_label_level == "hypernym" &  test_image_match_ground_truth_category == 1 ~ 1,
      TRUE ~ 0
    )
  ) %>%
  mutate(
    total_number_correct_options_label = case_when(
      current_category_label_level == "narrow" ~ 2,
      current_category_label_level == "intermediate" ~ 4,
      current_category_label_level == "broad" ~ 8,
      current_category_label_level == "hypernym" ~ 16
    ),
    total_number_correct_options_training = case_when(
      current_category_training_level == "narrow" ~ 2,
      current_category_training_level == "intermediate" ~ 4,
      current_category_training_level == "broad" ~ 8
    )
  ) %>%
  mutate(
    is_match_to_training = case_when(
      test_image_type_training_consistent == is_chosen ~ 1,
      TRUE ~ 0
    ),
    is_match_to_label = case_when(
      test_image_type_label_consistent == is_chosen ~ 1,
      TRUE ~ 0
    ),
    label_matches_training = case_when(
      current_category_training_level == current_category_label_level ~ 1,
      TRUE ~ 0
    )
  ) %>%
  mutate(
    hit_training = ifelse(test_image_type_training_consistent == 1, is_match_to_training,NA),
    hit_label = ifelse(test_image_type_label_consistent == 1, is_match_to_label,NA),
    false_alarm_training = ifelse(test_image_type_training_consistent == 0,1-is_match_to_training,NA),
    false_alarm_label = ifelse(test_image_type_label_consistent == 0,1-is_match_to_label,NA),
  )

#combine with sampling data
test_array_options_clean <- test_array_options_clean %>%
  left_join(sampling_data)

# write test data (longer representation)
write_csv(test_array_options_clean,here(write_path,"catact-v1-test-data-long.csv"))

#write final data set
write_csv(d,here(write_path,"catact-v1-alldata-processed.csv"))