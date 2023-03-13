# Libraries ====================================================================
library(dplyr)
library(data.table)
library(FITfileR)
library(googlesheets4)
library(ggplot2)


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
# Read in test log (from google sheets) ----------------------------------------
read_sheet("https://docs.google.com/spreadsheets/d/1IFuQUhQ1Ek6JTa5X2ZJpFEfSUxeqYrXXT58_0c2Hp1k") %>% 
  data.table() ->
  tests


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
           sheet=2) %>% 
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

# - reduced the tst data to take away post-lap observations
rides[distance <= lap_length] ->
  rides
















# Convert power to average over test (use to remove errors) ====================
rides[, power := mean(power), by=test_id][power %in% c(150, 225, 300, 900)] ->
  rides


# Add sectors ==================================================================
# TODO -------------------------------------------------------------------------


# - 
# distance_test[, lap := 1+(distance%/%..lap_length)]
# distance_test[, lap_distance := distance - min(distance), by=lap]
# 





# Summarise ====================================================================
rides[, .("seconds"=max(time), 
          "time"=seconds_to_time(max(time)),
          "speed"=max(distance)/max(time)*3.6), keyby=.(power, frame, wheel)][
            order(power, -speed)] -> 
  test_summary


test_summary[power<=300] %>% 
  ggplot(aes(x=power, y=speed, colour=frame, shape=wheel)) +
    geom_point(alpha=0.4) +
    geom_line() +
    theme(legend.position="none")




# Summarise Sectors ============================================================
rides[!is.na(sector), 
      .("speed"=max(distance)/max(time)*3.6),
      keyby=.(sector, power, frame, wheel)] ->
  sector_summary


sector_summary[power<=300, dcast(.SD, ...~sector, value.var="speed")] %>% 
  ggplot(aes(x=`ocean boulevard`, y=`epic kom`, colour=frame, shape=wheel)) +
    geom_point(alpha=0.4)




# ZwifterBikes =================================================================
tests[!is.na(zb_hrs), zb := (3600*zb_hrs + 60*zb_mins + zb_secs)]


tests[, .(frame, wheel, power, zb)][
  test_summary[power==300, .(frame, wheel, power, seconds)], 
  on=c("frame", "wheel", "power")] %>% 
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
    geom_smooth(method="lm", se = FALSE, fullrange=TRUE)


tests[, .(frame, wheel, power, zb)][
  test_summary[power==300, .(frame, wheel, power, seconds)], 
  on=c("frame", "wheel", "power")][, summary(lm(seconds~zb))]







