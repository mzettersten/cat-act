library(here)
library(tidyverse)

data_directory <- here("..","..","data","v3","raw")
processed_data_directory <- here("..","..","data","v3","processed")
file_name <- "catact-v3"

merge_and_deidentify_data <- function(raw_data_directory, 
                                      merged_data_path, 
                                      min_row=32) {
  
  raw_files <- here(raw_data_directory, dir(here(raw_data_directory), "*.csv"))
  
  #read data
  raw_data <- map_df(raw_files, function(file) {
    d <- read_csv(file) %>% 
      mutate(
        file_name = file 
      )
  }) 
  
  # count how many rows in each file 
  raw_count <- raw_data %>% 
    group_by(file_name) %>%
    count() 
  
  raw_data <- raw_data %>%
    left_join(raw_count)
  
  #remove abbreviated responses
  cleaned_data <- raw_data %>%
    filter(n>=min_row) 
  
  #remove workerIds
  anonymized_data <- cleaned_data %>%
    select(-workerId)
  
  #keep cleaned data for verifying participation
  write_csv(cleaned_data, here(merged_data_path,paste0(file_name,"-alldata.csv")))
  
  #keep anonymized data
  write_csv(anonymized_data, here(merged_data_path,paste0(file_name,"-alldata-anonymized.csv")))
  
}


merge_and_deidentify_data(data_directory, processed_data_directory)
