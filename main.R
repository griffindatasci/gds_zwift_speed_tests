# TODO: All combos of wheel and bike
# TODO: Animate sector plot


# Libraries ====================================================================
library(dplyr)
library(data.table)
library(FITfileR)
library(googlesheets4)
library(ggplot2)
library(gifski)
library(gganimate)


# Function: Seconds formatted as time ==========================================
seconds_to_time <- function(seconds, return_hours=TRUE, return_seconds=TRUE){
  if(return_hours==TRUE){
    time <- sprintf("%02.f:%02.f:%02.f", seconds%/%3600, seconds%%3600%/%60, seconds%%3600%%60)
  } else {
    time <- sprintf("%02.f:%02.f", seconds%/%60, seconds%%3600%%60)
  }
  if(return_seconds==FALSE){
    time <- (paste0(tstrsplit(time, ":")[[1]], ":", tstrsplit(time, ":")[[2]]))
  }
  return(time)
}


# DATA =========================================================================
# Read .fit files and write to .csv (quicker loading) --------------------------
# - List of .fit files, reduced to those not already saved as .csvs
fit_files <- gsub(".fit", "", list.files("fit_files", pattern=".fit"))
fit_files <- fit_files[!(fit_files %in% gsub(".csv", "", list.files("csv_files/", pattern=".csv")))]


# - Load fit files and read to CSVs
lapply(fit_files,
       function(file){
         readFitFile(paste0("fit_files/", file, ".fit")) %>%
           records() %>%
           fwrite(file=paste0("csv_files/", file, ".csv"))
       })


# Read in test log (from google sheets) ----------------------------------------
read_sheet("https://docs.google.com/spreadsheets/d/1IFuQUhQ1Ek6JTa5X2ZJpFEfSUxeqYrXXT58_0c2Hp1k",
           sheet="test_data") %>% 
data.table() ->
  tests


if(length(tests[!is.na(url), test_id][!(tests[!is.na(url), test_id] %in% gsub(".csv", "", list.files("csv_files/", pattern=".csv")))])>0){
  stop("Not all rides are downloaded.")
}


# Read in ride data into a single dataset --------------------------------------
list.files("csv_files/", pattern=".csv") %>% 
  lapply(function(file){
    fread(paste0("csv_files/", file))[, c("test_id"=gsub(".csv", "", file), .SD)]
  }) %>% 
  rbindlist() ->
  rides 


# Merge on test data (frame, wheel, start time) --------------------------------
tests[, .(test_id, start_seconds, frame, wheel)][rides, on="test_id"] ->
  rides


# Get ride time and remove lead-in (time before start line) --------------------
rides[, time := as.numeric(timestamp-min(timestamp)), by=test_id][
  time>=start_seconds, -c("start_seconds")] ->
  rides


# Make ride time/distance relative to start ------------------------------------
rides[, time := time - min(time), by=test_id]
rides[, distance := distance - min(distance), by=test_id]


# Remove ride after finish line ------------------------------------------------
# - read in data from the distance test (50 laps of mountain route)
fread("Mountain_Route_Distance_Test.csv") ->
  distance_test 

# - acivity seconds
distance_test[, time:=as.numeric(timestamp-min(timestamp))]

# - read in markers data (timestamps at 25 landmarks on lap 1 and 51)
read_sheet("https://docs.google.com/spreadsheets/d/1IFuQUhQ1Ek6JTa5X2ZJpFEfSUxeqYrXXT58_0c2Hp1k",
           sheet="mountain_route_markers") %>% 
  data.table() ->
  markers

# - timestamps as seconds
markers[, start := mins_1*60 + secs_1]
markers[, end := hrs_51*3600 + mins_51*60 + secs_51]

# - pivot to allow merger
markers <- markers[, .(marker, start, end)][, melt(.SD, id.vars="marker")][, -c("variable")]
setnames(markers, c("marker", "time"))

# - merge on to mark relevant observations
distance_test <- markers[distance_test, on="time"]

# - calculate lap lengths (mean across 25 markers)
distance_test[!is.na(marker), 
              .("distance"=max(distance-min(distance))/50),
              by=marker][, mean(distance)] ->
  lap_length 

# - reduced the test data to take away post-lap observations
rides[distance <= lap_length] ->
  rides


# Convert power to average over test (use to remove errors) ====================
rides[, power := mean(power), by=test_id][power %in% c(150, 225, 300, 900)] ->
  rides


# Add sectors ==================================================================
distance_test[, lap := 1+(distance%/%..lap_length)]
distance_test[, lap_distance := distance - min(distance), by=lap]
distance_test[marker %in% c("start banner", "int epic-desert",
                            "epic start", "epic banner",
                            "bonus climb start", "bonus topstone",
                            "bonus down rail", "bonus descent end",
                            "int island-castle", "int villas-seq",
                            "int volcano-sprint", "int volcano-downtown"), mean(lap_distance), 
              by=marker][, .(rep(c("Ocean Blvd.", "Epic Climb", "Radio Climb", "Radio Descent",
                                   "Epic Descent", "Sequoia to Downtown"), each = 2),
                             rep(c("start", "finish"), times=6), 
                             "distance"=V1)][, dcast(.SD, ...~V2, value.var="distance")][
              order(start), .("sector"=V1, start, finish)] ->
  sector_key

for(i in seq(sector_key[,.N])){
  rides[sector_key[i, start]<=distance & 
        sector_key[i, finish]>=distance, 
        sector:=sector_key[i, sector]]
}


# Generate test summary table ==================================================
rides[, .("seconds"=max(time), 
          "time"=seconds_to_time(max(time)),
          "speed"=max(distance)/max(time)*3.6), keyby=.(power, frame, wheel)][
            order(power, -speed)] -> 
  test_summary


# All combinations of frame and wheel ==========================================
crossed <- rbindlist(lapply(c(150, 225, 300), function(watts){
  # - Get baseline time (time for Zwift Aero frame + Zwift 32mm Carbon wheels)
  baseline <- test_summary[power==watts & frame=="Zwift Aero" & wheel=="Zwift 32mm Carbon", speed]
  
  # - Get speed relative to baseline
  test_summary[power==watts, relative:= speed-..baseline]
  
  # - Get effect of each frame (excl. TRON at this point - not paired with 32mm)
  frames <- test_summary[power==watts & frame!="TRON" & wheel=="Zwift 32mm Carbon", 
                         .(frame, "frame_effect"=relative)]
 
  # - Get effect of each wheelset
  wheels <- test_summary[power==watts & frame=="Zwift Aero", 
                         .(wheel, "wheel_effect"=relative)]
  
  # Cross-join to get all combinations (this is returned by lapply() )
  setkey(frames[, c(k=1, .SD)], k)[wheels[, c(k=1, .SD)], allow.cartesian=TRUE][, k:=NULL][, 
          .(frame, wheel, "power"=..watts, "speed"=frame_effect + wheel_effect + ..baseline)]
  
}))

# - Add TRON
crossed <- rbind(crossed, test_summary[frame=="TRON", .(frame, wheel, power, speed)])

# - Derive **predicted** seconds/time
crossed[, "seconds":=..lap_length/speed*3.6]
crossed[, "time":=seconds_to_time(seconds)]




# Summarise ====================================================================
crossed[power!=900 & power!=225, 
             .(frame, wheel, "cost"=seconds-min(seconds)), 
             by=power] %>% 
  ggplot(aes(x=power, y=cost, colour=frame, shape=wheel)) +
  geom_point(alpha=0.5) +
  geom_path() +
  scale_y_reverse("Seconds Behind Fastest Bike") +
  scale_x_continuous("Power",
                     breaks=c(150,300),
                     labels=c("150W (2W/kg)", "300W (4W/kg)")) +
  labs(colour="Frame", shape="Wheel") +
  theme_classic() ->
  crossover_plot







# Summarise Sectors ============================================================
# - Need to get speeds for sectors
# - Apply that to all bikes
# - Plot predicted speed for each sector
# - Need to animate by power to show how cloud shape changes with power

rides[!is.na(sector), 
      .("speed"=max(distance)/max(time)*3.6),
      keyby=.(sector, power, frame, wheel)] ->
  sector_summary

sector_summary[, speed:=scale(speed), by=.(power, sector)]
sector_summary[power<=300, dcast(.SD, ...~sector, value.var="speed")] %>% 
  ggplot(aes(x=`Ocean Blvd.`, y=`Epic Climb`, colour=as.factor(power))) +
  geom_point() +
  geom_smooth(method = "lm", se=FALSE) +
  labs(x="Flat Speed", y="Climb Speed", colour="Power (W)") +
  theme_classic()






# ZwifterBikes =================================================================
read_sheet("https://docs.google.com/spreadsheets/d/1IFuQUhQ1Ek6JTa5X2ZJpFEfSUxeqYrXXT58_0c2Hp1k",
           sheet="zwifterbikes") %>% 
  data.table() ->
  zwifterbikes

zwifterbikes[, zb:=hours*3600 + minutes*60 + seconds]

zwifterbikes <- zwifterbikes[, .(frame, wheel, zb)][
  crossed[power==300, .(frame, wheel, seconds)], 
  on=c("frame", "wheel")]

zwifterbikes %>% 
  ggplot(aes(x=zb, y=seconds)) +
  geom_abline(intercept=0, slope=1) +
  scale_x_continuous("ZwifterBikes predicted time (hh:mm)", 
                     limits=c(3200,3900),
                     breaks=seq(0, 100000, 120),
                     labels=seconds_to_time(seq(0, 100000, 120), return_seconds=FALSE)) +
  scale_y_continuous("Actual time (hh:mm)", 
                     limits=c(3200,3900),
                     breaks=seq(0, 100000, 120),
                     labels=seconds_to_time(seq(0, 100000, 120), return_seconds=FALSE)) +
  coord_equal() +
  geom_point() +
  geom_smooth(method="lm", se = FALSE, fullrange=TRUE) ->
  zb_plot


zwifterbikes[, summary(lm(seconds~zb))]


zwifterbikes[, range(zb-seconds)]




