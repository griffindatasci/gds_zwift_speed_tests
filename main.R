# - Read in datasets (tests = tests + strava + zwifterbikes)
# - Create dataset with predicted times for all bikes
library(data.table)
library(googlesheets4)

sheet_url <- "https://docs.google.com/spreadsheets/d/1IFuQUhQ1Ek6JTa5X2ZJpFEfSUxeqYrXXT58_0c2Hp1k"




# READ DATA ====================================================================
# - Main Test Log
tests <- data.table(read_sheet(sheet_url, sheet="tests"), key="test_id")[
  !is.na(start_seconds), .(test_id, frame, wheel, power)]


# - Strava Times
strava_times <- data.table(read_sheet(sheet_url, sheet="strava_times"), key="test_id")[, .(test_id, route, ocean, epic, radio)]


# - Merge
tests <- tests[strava_times][frame!="Pinarello Dogma F"]




# CROSS FOR ALL BIKES ==========================================================
all_bikes <- rbindlist(lapply(c(150,300), function(watts){
  
  # - Time relative to BL
  tests[power==watts, 
        c("effect_route", "effect_ocean", "effect_epic", "effect_radio") :=
          .(route   -tests[frame=="Zwift Aero" & wheel=="Zwift 32mm Carbon" & power==watts, route],
            ocean   -tests[frame=="Zwift Aero" & wheel=="Zwift 32mm Carbon" & power==watts, ocean],
            epic    -tests[frame=="Zwift Aero" & wheel=="Zwift 32mm Carbon" & power==watts, epic],
            radio   -tests[frame=="Zwift Aero" & wheel=="Zwift 32mm Carbon" & power==watts, radio])]
  
  
  # - Get effect of each frame (excl. TRON at this point - not paired with 32mm)
  frames <- tests[power==watts & frame!="TRON" & wheel=="Zwift 32mm Carbon", 
                  .(frame, 
                    "frame_route"=effect_route, 
                    "frame_ocean"=effect_ocean, 
                    "frame_epic"=effect_epic, 
                    "frame_radio"=effect_radio)]
  
  
  # - Get effect of each wheelset
  wheels <- tests[power==watts & frame=="Zwift Aero",  
                  .(wheel, 
                    "wheel_route"=effect_route, 
                    "wheel_ocean"=effect_ocean, 
                    "wheel_epic"=effect_epic, 
                    "wheel_radio"=effect_radio)]
  
  
  # - Cross-join to get all combinations (this is returned by lapply() )
  crossed <- setkey(frames[, c(k=1, .SD)], k)[wheels[, c(k=1, .SD)], allow.cartesian=TRUE][, k:=NULL][, 
                                                                                                      .(frame, wheel, "power"=..watts, 
                                                                                                        "route"=frame_route + wheel_route + tests[frame=="Zwift Aero" & wheel=="Zwift 32mm Carbon" & power==watts, route], 
                                                                                                        "ocean"=frame_ocean + wheel_ocean + tests[frame=="Zwift Aero" & wheel=="Zwift 32mm Carbon" & power==watts, ocean], 
                                                                                                        "epic"=frame_epic + wheel_epic + tests[frame=="Zwift Aero" & wheel=="Zwift 32mm Carbon" & power==watts, epic], 
                                                                                                        "radio"=frame_radio + wheel_radio + tests[frame=="Zwift Aero" & wheel=="Zwift 32mm Carbon" & power==watts, radio])]
  
  
  # - Add TRON
  rbind(crossed, tests[frame=="TRON" & power==watts, .(frame, wheel, power, route, ocean, epic, radio)])
}))