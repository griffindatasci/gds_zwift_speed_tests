rm(list=ls())

library(data.table)
library(googlesheets4)


# Read in test data ------------------------------------------------------------
book_url <- "https://docs.google.com/spreadsheets/d/1IFuQUhQ1Ek6JTa5X2ZJpFEfSUxeqYrXXT58_0c2Hp1k"

test_data <- data.table(read_sheet(book_url, sheet = "new_mr"))


test_data[, c("route", "ocean", "epic_climb", "radio_climb", "radio_descent", "epic_descent", "windfarm") :=
            .(as.numeric(unlist(route_h))*3600 + route_m*60 + route_s,
              ocean_m*60 + ocean_s,
              epic_climb_m*60 + epic_climb_s,
              radio_climb_m*60 + radio_climb_s,
              radio_descent_m*60 + radio_descent_s,
              epic_descent_m*60 + epic_descent_s,
              windfarm_m*60 + windfarm_s)]

test_data <- test_data[, .(test, lap, frame, wheel, power, route, ocean, epic_climb, radio_climb, radio_descent, epic_descent, windfarm)]


# Get mean times per test variant ----------------------------------------------
test_means <- test_data[, .("route"=mean(route), "ocean"=mean(ocean), "epic_climb"=mean(epic_climb),
                            "radio_climb"=mean(radio_climb), "radio_descent"=mean(radio_descent),
                            "epic_descent"=mean(epic_descent), "windfarm"=mean(windfarm)), 
                        by=.(test, frame, wheel, power)]



# Get times for all bikes ------------------------------------------------------
test_means[, baseline := ifelse(frame=="Zwift Aero"&wheel=="Zwift 32mm Carbon", TRUE, FALSE)]


all_bikes <- rbindlist(lapply(c(150,300), function(watts){
  
  # - Time relative to BL
  test_means[power==watts, 
        c("route_eff", "ocean_eff", "epic_climb_eff", "radio_climb_eff", 
          "radio_descent_eff", "epic_descent_eff", "windfarm_eff") :=
          .(route - test_means[baseline==TRUE & power==watts, route],
            ocean -test_means[baseline==TRUE & power==watts, ocean],
            epic_climb -test_means[baseline==TRUE & power==watts, epic_climb],
            radio_climb - test_means[baseline==TRUE & power==watts, radio_climb],
            radio_descent - test_means[baseline==TRUE & power==watts, radio_descent],
            epic_descent - test_means[baseline==TRUE & power==watts, epic_descent],
            windfarm - test_means[baseline==TRUE & power==watts, windfarm])]
  
  
  # - Get effect of each frame (excl. TRON at this point - not paired with 32mm)
  frames <- test_means[power==watts & frame!="TRON" & wheel=="Zwift 32mm Carbon", 
                  .(frame, "route_fr"=route_eff, "ocean_fr"=ocean_eff, "epic_climb_fr"=epic_climb_eff,
                    "radio_climb_fr"=radio_climb_eff, "radio_descent_fr"=radio_descent_eff, 
                    "epic_descent_fr"=epic_descent_eff, "windfarm_fr"=windfarm_eff)]
  
  
  # - Get effect of each wheelset
  wheels <- test_means[power==watts & frame!="TRON" & frame=="Zwift Aero", 
                       .(wheel, "route_wh"=route_eff, "ocean_wh"=ocean_eff, "epic_climb_wh"=epic_climb_eff,
                         "radio_climb_wh"=radio_climb_eff, "radio_descent_wh"=radio_descent_eff, 
                         "epic_descent_wh"=epic_descent_eff, "windfarm_wh"=windfarm_eff)]
  
  
  
  # - Cross-join to get all combinations (this is returned by lapply() )
  crossed <- setkey(frames[, c(k=1, .SD)], k)[wheels[, c(k=1, .SD)], allow.cartesian=TRUE][, k:=NULL][, 
                                                                                                      .(frame, wheel, "power"=..watts, 
                                                                                                        "route"=route_fr + route_wh + test_means[baseline==TRUE & power==watts, route], 
                                                                                                        "ocean"=ocean_fr + ocean_wh + test_means[baseline==TRUE & power==watts, ocean], 
                                                                                                        "epic_climb"=epic_climb_fr + epic_climb_wh + test_means[baseline==TRUE & power==watts, epic_climb], 
                                                                                                        "radio_climb"=radio_climb_fr + radio_climb_wh + test_means[baseline==TRUE & power==watts, radio_climb], 
                                                                                                        "radio_descent"=radio_descent_fr + radio_descent_wh + test_means[baseline==TRUE & power==watts, radio_descent], 
                                                                                                        "epic_descent"=epic_descent_fr + epic_descent_wh + test_means[baseline==TRUE & power==watts, epic_descent], 
                                                                                                        "windfarm"=windfarm_fr + windfarm_wh + test_means[baseline==TRUE & power==watts, windfarm]
                                                                                                        )]
  
  
  # - Add TRON
  rbind(crossed, test_means[frame=="TRON" & power==watts, .(frame, wheel, power, route, ocean, epic_climb, radio_climb, radio_descent, epic_descent, windfarm)])
}))








all_bikes[, radio_climb := rnorm(.N, 660, 20)+power]
all_bikes[, ocean := rnorm(.N, 660, 20)+power]


# Top 5 bikes at 300 watts
# - whole route
all_bikes[power==300][order(route), .(frame, wheel, route)][1:5]
# - ocean
all_bikes[power==300][order(ocean), .(frame, wheel, ocean)][1:5]
# - epic climb
all_bikes[power==300][order(epic_climb), .(frame, wheel, epic_climb)][1:5]

# Top 5 bikes at 150 watts
# - whole route
all_bikes[power==150][order(route), .(frame, wheel, route)][1:5]
# - ocean
all_bikes[power==150][order(ocean), .(frame, wheel, ocean)][1:5]
# - epic climb
all_bikes[power==150][order(epic_climb), .(frame, wheel, epic_climb)][1:5]



all_bikes[frame!="Zwift Aero" & wheel!="Zwift 32mm Carbon", .("focal"=ocean-min(ocean), frame, wheel), by=power][
  , ggplot(.SD, aes(x=as.factor(power), y=focal, color=frame, shape=wheel, group=paste0(frame, wheel))) +
    geom_path() +
    geom_point() +
    scale_y_reverse() +
    scale_x_discrete(expand=c(0.1,0)) +
    theme_classic() +
    labs(x="Power", y="Time Behind Fastest (s)", color="Frame", shape="Wheelset")
]
