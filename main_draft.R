library(rvest)
library(dplyr)
library(data.table)
library(ggplot2)
library(googlesheets4)
options(googlesheets4_quiet=TRUE)

update_segments <- TRUE
sheet_url <- "https://docs.google.com/spreadsheets/d/1IFuQUhQ1Ek6JTa5X2ZJpFEfSUxeqYrXXT58_0c2Hp1k"
focal_tests <- sprintf("WMR%05.f", c(59L:100L))


# get test_log -----------------------------------------------------------------
test_log <- read_sheet(sheet_url, sheet="test_log")
1
test_log <- data.table(test_log)[
  test_id%in%focal_tests, .(test_id, frame, wheel, power)]


# get segment times ------------------------------------------------------------
if(update_segments){
  for(page_source in list.files("source_files/")){
    
    # Read in view-source file
    page_body <- 
      read_html(paste0("source_files/", page_source)) %>% 
      html_node("body") %>% 
      html_text() %>% 
      tstrsplit("pageView.segmentEfforts")
    
    
    
    # Extract test identifier (name of activity)
    test_id <- page_body %>% 
      tstrsplit("title") 
    
    
    test_id <- tstrsplit(gsub(">", "", test_id[[2]][1]), " ")[[1]]
    
    if(!test_id%in%read_sheet(sheet_url, "segment_times")$test_id){
      
      
      # Get KOM data
      kom_section <- 
        page_body[[2]] %>% 
        tstrsplit("pageView.activity")
      
      
      kom_section <- kom_section[[1]]
      
      
      kom_data <- 
        kom_section %>% 
        tstrsplit("start_index")
      
      
      kom_index <- sapply(kom_data, function(kom) {
        grepl('Mountain Route"|Ocean Blvd."|Epic KOM"|Radio Tower Climb"|Radio Descent"|Epic Rev. Descent"|Windfarm to Downtown"', kom)
      })
      
      
      kom_times <- sapply(kom_data[kom_index], function(kom){
        diff(
          as.numeric(
            gsub('"|:|,', "", 
                 c(tstrsplit(kom, "end_index")[[1]], 
                   tstrsplit(tstrsplit(kom, "end_index")[[2]], 
                             "flagged")[[1]]))))
      })
      
      kom_times <- data.table(test_id, 
                              lap=c(1L:(length(kom_times)%/%7)), 
                              matrix(kom_times[1:(length(kom_times)%/%7*7)], 
                                     nrow=(length(kom_times)%/%7), byrow=TRUE))
      
      
      setnames(kom_times, c("test_id", "lap", "route", "ocean", "epic_climb", "radio_climb", "radio_descent", "epic_descent", "windfarm"))
      
      kom_times <- test_log[, .(test_id, frame, wheel, power)][kom_times, on="test_id"]
      
      sheet_append(sheet_url, data=kom_times, sheet="segment_times")
    }
    
    print(paste("Test", test_id, "complete!"))
  }
}


segment_times <- data.table(read_sheet(sheet_url, "segment_times"))[test_id%in%focal_tests]




# get mean times -------------------------------------------------------------
segment_times[, laps:=.N, by=.(frame, wheel, power)]

# - flag suspicious times (those differing by >2 seconds from frame/wheel/power median)
segment_times[, flag := ifelse(1>=
  segment_times[, -c("lap", "test_id")][
    , lapply(.SD, function(j){abs(j-median(j))}), by=.(frame, wheel, power, laps)][
      , -c("frame", "wheel", "power", "laps")][, apply(.SD, 1, max)], FALSE, TRUE)]


# - restrict to tests with 2+ laps
flagged_laps <- segment_times[flag==TRUE]
segment_times <- segment_times[flag!=TRUE]
segment_times[, laps:=.N, by=.(frame, wheel, power)]
segment_times <- segment_times[laps>=2, -c("flag")]


# - mean times per segment
test_data <- segment_times[, -c("lap", "test_id")][, lapply(.SD, mean), by=.(frame, wheel, power)]



# get all bikes ----------------------------------------------------------------
test_data[, baseline := ifelse(frame=="Zwift Aero"&wheel=="Zwift 32mm Carbon", TRUE, FALSE)]


all_bikes <- rbindlist(lapply(c(150,300), function(watts){
  
  # - Time relative to BL
  test_data[power==watts, 
             c("route_eff", "ocean_eff", "epic_climb_eff", "radio_climb_eff", 
               "radio_descent_eff", "epic_descent_eff", "windfarm_eff") :=
               .(route - test_data[baseline==TRUE & power==watts, route],
                 ocean -test_data[baseline==TRUE & power==watts, ocean],
                 epic_climb -test_data[baseline==TRUE & power==watts, epic_climb],
                 radio_climb - test_data[baseline==TRUE & power==watts, radio_climb],
                 radio_descent - test_data[baseline==TRUE & power==watts, radio_descent],
                 epic_descent - test_data[baseline==TRUE & power==watts, epic_descent],
                 windfarm - test_data[baseline==TRUE & power==watts, windfarm])]
  
  
  # - Get effect of each frame (excl. TRON at this point - not paired with 32mm)
  frames <- test_data[power==watts & frame!="TRON" & wheel=="Zwift 32mm Carbon", 
                       .(frame, "route_fr"=route_eff, "ocean_fr"=ocean_eff, "epic_climb_fr"=epic_climb_eff,
                         "radio_climb_fr"=radio_climb_eff, "radio_descent_fr"=radio_descent_eff, 
                         "epic_descent_fr"=epic_descent_eff, "windfarm_fr"=windfarm_eff)]
  
  
  # - Get effect of each wheelset
  wheels <- test_data[power==watts & frame!="TRON" & frame=="Zwift Aero", 
                       .(wheel, "route_wh"=route_eff, "ocean_wh"=ocean_eff, "epic_climb_wh"=epic_climb_eff,
                         "radio_climb_wh"=radio_climb_eff, "radio_descent_wh"=radio_descent_eff, 
                         "epic_descent_wh"=epic_descent_eff, "windfarm_wh"=windfarm_eff)]
  
  
  
  # - Cross-join to get all combinations (this is returned by lapply() )
  crossed <- setkey(frames[, c(k=1, .SD)], k)[wheels[, c(k=1, .SD)], allow.cartesian=TRUE][, k:=NULL][
    , 
    .(frame, wheel, "power"=..watts, 
      "route"=route_fr + route_wh + test_data[baseline==TRUE & power==watts, route], 
      "ocean"=ocean_fr + ocean_wh + test_data[baseline==TRUE & power==watts, ocean], 
      "epic_climb"=epic_climb_fr + epic_climb_wh + test_data[baseline==TRUE & power==watts, epic_climb], 
      "radio_climb"=radio_climb_fr + radio_climb_wh + test_data[baseline==TRUE & power==watts, radio_climb], 
      "radio_descent"=radio_descent_fr + radio_descent_wh + test_data[baseline==TRUE & power==watts, radio_descent], 
      "epic_descent"=epic_descent_fr + epic_descent_wh + test_data[baseline==TRUE & power==watts, epic_descent], 
      "windfarm"=windfarm_fr + windfarm_wh + test_data[baseline==TRUE & power==watts, windfarm]
    )]
  
  
  # - Add TRON
  rbind(crossed, test_data[frame=="TRON" & power==watts, .(frame, wheel, power, route, ocean, epic_climb, radio_climb, radio_descent, epic_descent, windfarm)])
}))


all_bikes


all_bikes[, route_kmh:=29490/route*3.6]
all_bikes[, ocean_kmh:= 4140/ocean*3.6]
all_bikes[, epic_climb_kmh:= 9410/epic_climb*3.6]
all_bikes[, radio_climb_kmh:= 1090/radio_climb*3.6]
all_bikes[, radio_descent_kmh:= 1120/radio_descent*3.6]
all_bikes[, epic_descent_kmh:= 5640/epic_descent*3.6]
all_bikes[, windfarm_kmh:= 5880/windfarm*3.6]



# Tests to do as prioity:
test_data[, .("w150"=max(power==150), "w300"=max(power==300)), by=.(frame, wheel)]
