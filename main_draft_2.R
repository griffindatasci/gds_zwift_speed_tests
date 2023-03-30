library(rvest)
library(dplyr)
library(data.table)
#library(ggplot2)
library(googlesheets4)
options(googlesheets4_quiet=TRUE)
sheet_url <- "https://docs.google.com/spreadsheets/d/1IFuQUhQ1Ek6JTa5X2ZJpFEfSUxeqYrXXT58_0c2Hp1k"


void_tests <- "8751263111"

focal_koms <- c("Mountain Route", "Ocean Blvd.", "Epic KOM", "Radio Tower Climb",
                "Radio Descent", "Epic Rev. Descent", "Windfarm to Downtown")




# read in test log and extract ID from URL -------------------------------------
test_log <- read_sheet(sheet_url, sheet="new_test_log")
1 # to refresh oauth token if needed
test_log <- data.table(test_log)[!is.na(url), c("test_id"=.(tstrsplit(url, "/")[[5]]), .SD)][, -c("url")]


# get segment data -------------------------------------------------------------
focal_kom_string <- paste(focal_koms, collapse='"|')
segment_times <- data.table(read_sheet(sheet_url, "new_segment_times"))

for(file in list.files("source_files/")){
# for(file in "view-source_https___www.strava.com_activities_8797039570.html"){
  
  test_id <- gsub("view-source_https___www.strava.com_activities_|.html", "", file)
  
  if(!(test_id %in% segment_times[, test_id])){
    
    page_body <- 
      read_html(paste0("source_files/", file)) %>% 
      html_node("body") %>% 
      html_text() %>% 
      tstrsplit("pageView.segmentEfforts")
    
    
    kom_section <- 
      page_body[[2]] %>% 
      tstrsplit("pageView.activity")
    
    
    kom_section <- kom_section[[1]]
    
    
    kom_data <- 
      kom_section %>% 
      tstrsplit("start_index")
      #tstrsplit("elapsed_time_raw")
    
    
    kom_index <- sapply(kom_data, function(kom) {
      grepl(focal_kom_string, kom)
    })
    
    
    
    kom_times <- sapply(kom_data[kom_index], function(kom){
      as.numeric(tstrsplit(tstrsplit(gsub('"|\\\\',"", kom), "elapsed_time_raw:")[[2]], ",moving_time:")[[1]])
    })

    
    kom_times <- data.table(test_id, 
                            lap=c(1L:(length(kom_times)%/%length(focal_koms))), 
                            matrix(kom_times[1:(length(kom_times)%/%length(focal_koms)*length(focal_koms))], 
                                   nrow=(length(kom_times)%/%length(focal_koms)), byrow=TRUE))
    
    
    setnames(kom_times, c("test_id", "lap", gsub(" ", "_", gsub("[[:punct:]]", "", tolower(focal_koms)))))
    
    kom_times <- test_log[, .(test_id, frame, wheel, power)][kom_times, on="test_id"]
    
    sheet_append(sheet_url, data=kom_times, sheet="new_segment_times")
    
  }

  print(paste("Test", test_id, "complete!"))
  
}


segment_times <- data.table(read_sheet(sheet_url, "new_segment_times"))[!(test_id%in%void_tests)]



# identify outliers ------------------------------------------------------------
segment_times[, max:=segment_times[, -c("test_id", "lap")][, lapply(.SD, function(j){abs(j-median(j))}), keyby=.(frame, wheel, power)][, -c("frame", "wheel", "power")][, apply(.SD, 1, max)]]

segment_times[max>=2]


# get segment averages for all frame/wheel/power combinations with 3+ times from 2+ tests
segment_times[, -c("lap", "test_id", "max")][, lapply(.SD, mean), by=.(frame, wheel, power)]





# segment_times[, n_laps := .N, by=.(frame, wheel, power)]
# segment_times[, test_laps := .N, by=test_id]
# segment_times[, n_tests := uniqueN(test_id), by=.(frame, wheel, power)]
# 
# unique(segment_times[, .(frame, wheel, power, n_tests, n_laps)])
# 
