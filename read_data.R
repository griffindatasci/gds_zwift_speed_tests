library(data.table)
library(googlesheets4)


# Read in data from google sheets ----------------------------------------------
sheet_url <- "https://docs.google.com/spreadsheets/d/1IFuQUhQ1Ek6JTa5X2ZJpFEfSUxeqYrXXT58_0c2Hp1k"

tests        <- data.table(read_sheet(sheet_url, sheet="tests"))
1
zb_times     <- data.table(read_sheet(sheet_url, sheet="zb_times"))
strava_times <- data.table(read_sheet(sheet_url, sheet="strava_times"))


# Clean up datasets
tests <- tests[!is.na(date), .(test_id, frame, wheel, power)]

zb_times[, c("hours", "minutes", "seconds", "zb_time", "power") := 
           .(NULL, NULL, NULL, hours*3600 + minutes*60 + seconds, 300)]


tests <- tests[strava_times, on="test_id"]

rm(list=c("strava_times", "sheet_url"))