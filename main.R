library(dplyr)
library(data.table)
library(FITfileR)
library(googlesheets4)
library(ggplot2)



# Seconds formatted as time ====================================================
seconds_to_time <- function(seconds, hours=TRUE){
  if(hours==TRUE){
    time <- sprintf("%02.f:%02.f:%02.f", seconds%/%3600, seconds%%3600%/%60, seconds%%3600%%60)
  } else{
    time <- sprintf("%02.f:%02.f", seconds%/%60, seconds%%3600%%60)
  }
  return(time)
}




# Read in test log (from google sheets) ========================================
read_sheet("https://docs.google.com/spreadsheets/d/1IFuQUhQ1Ek6JTa5X2ZJpFEfSUxeqYrXXT58_0c2Hp1k") %>% 
  data.table() ->
  tests




# Read .fit files and write to .csv (quikcer loading) ==========================
# - List of .fit files, reduced to those not already saved as .csvs
fit_files <- gsub(".fit", "", list.files("fit_files", pattern=".fit"))

fit_files <- fit_files[!(fit_files %in% gsub(".csv", "", list.files("csv_files/", pattern=".csv")))]


# - Load fit files and read to CSVs
lapply(fit_files,
       function(file){
         readFitFile(paste0("fit_files/", file)) %>%
           records() %>%
           fwrite(file=paste0("csv_files/", gsub(".fit", ".csv", file)))
       })




# Read in ride data into a single dataset ======================================
list.files("csv_files/", pattern=".csv") %>% 
  lapply(function(file){
    fread(paste0("csv_files/", file))[, c("test_id"=gsub(".csv", "", file), .SD)]
  }) %>% 
  rbindlist() ->
  rides 




# Merge on test data (frame, wheel, start time) ================================
tests[, .(test_id, start_seconds, frame, wheel)][rides, on="test_id"] ->
  rides




# Get ride time and remove lead-in (time before start line) ====================
rides[, time := as.numeric(timestamp-min(timestamp)), by=test_id][
  time>=start_seconds, -c("start_seconds")] ->
  rides




# Make ride time/distance relative to start ====================================
rides[, time := time - min(time), by=test_id]
rides[, distance := distance - min(distance), by=test_id]




# Remove ride after finish line ================================================
lap_length <- 1386/47*1000  # do dynamically from testing
rides[distance <= lap_length] ->
  rides




# Convert power to average over test (use to remove errors) ====================
rides[, power := mean(power), by=test_id][power %in% c(150, 225, 300, 900)] ->
  rides










# Add sectors ==================================================================
rides[distance>  500&distance<= 4500, sector:="ocean boulevard"]
rides[distance> 5500&distance<= 9500, sector:="epic kom"]











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
      .("speed"=max(distance-min(distance))/max(time-min(time))*3.6),
      keyby=.(sector, power, frame, wheel)] ->
  sector_summary


sector_summary[power<=300, dcast(.SD, ...~sector, value.var="speed")] %>% 
  ggplot(aes(x=`ocean boulevard`, y=`epic kom`, colour=frame, shape=wheel)) +
    geom_point(alpha=0.4)

