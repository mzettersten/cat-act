library(here)
library(tidyverse)
library(jsonlite)
library(tidyjson)
library(rlang)
source("helper.R")

data_path <- here("..","..","data","v1","processed", "catact-v1-alldata.csv")
cloud_path <- here("..","..","data","v1","processed","catact_v1_cloudresearch_submissions.csv")
qualtrics_path <- here("..","..","data","v1","processed","CatAct_V1_January 26, 2023_14.09_processed.csv")

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
## one cloud participant missing for unknown reasons

setdiff(unique_pavlovia_participants$workerId,qualtrics$workerId)
setdiff(qualtrics$workerId,unique_pavlovia_participants$workerId)

#### join
cloud_submitted <- cloud_submitted %>%
  left_join(unique_pavlovia_participants, by=c("AmazonIdentifier"="workerId"))

sum(cloud_submitted$`Actual Completion Code`==cloud_submitted$code,na.rm=TRUE)
#one participant entered their workerId instead of a completion code

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
