library(data.table)
library(FITfileR)

fit_files <- list.files("fit_files", pattern=".fit")
csv_files <- list.files("csv_files", pattern=".csv")

new_files <- fit_files[gsub(".fit", "", fit_files) %in% gsub(".fit", ".csv", csv_files)]

lapply(new_files, function(file){
  fwrite(records(readFitFile(paste0("fit_files/", file))), 
         file=paste0("csv_files/", gsub(".fit", ".csv", file)))
})



rides <- rbindlist(
  lapply(
    list.files("csv_files", pattern=".csv"),
    function(file){
      fread(paste0("csv_files/", file))[, c("test_id"=gsub(".csv", "", file), .SD)] 
    })
  )[, .("time"=as.numeric(timestamp-min(timestamp)), distance, power), by=test_id] 


rm(list=c("fit_files", "csv_files", "new_files"))
