rm(list=ls())

library(ggplot2)

source("read_data.R")



# All combinations of frame and wheel ------------------------------------------
crossed <- rbindlist(lapply(c(150, 225, 300), function(watts){
  # - Get baseline time (time for Zwift Aero frame + Zwift 32mm Carbon wheels)
  baseline <- tests[power==watts & frame=="Zwift Aero" & wheel=="Zwift 32mm Carbon", route]
  
  # - Get speed relative to baseline
  tests[power==watts, relative:= route-..baseline]
  
  # - Get effect of each frame (excl. TRON at this point - not paired with 32mm)
  frames <- tests[power==watts & frame!="TRON" & wheel=="Zwift 32mm Carbon", 
                         .(frame, "frame_effect"=relative)]
  
  # - Get effect of each wheelset
  wheels <- tests[power==watts & frame=="Zwift Aero", 
                         .(wheel, "wheel_effect"=relative)]
  
  # - Cross-join to get all combinations (this is returned by lapply() )
  setkey(frames[, c(k=1, .SD)], k)[wheels[, c(k=1, .SD)], allow.cartesian=TRUE][, k:=NULL][, 
      .(frame, wheel, "power"=..watts, "route"=frame_effect + wheel_effect + ..baseline)]
  
}))

# - Add TRON
crossed <- rbind(crossed, 
                 tests[frame=="TRON", .(frame, wheel, power, route)])




# "cost" = time behind fastest bike (within power level) -----------------------
crossed[, cost:=route-min(route, na.rm=TRUE), by=power]
crossed[, cost_rank:=frank(cost, ties.method="min"), by=power]
crossed[, best_rank:=min(cost_rank), by=.(frame, wheel)]




# Table of top performers at 300W ----------------------------------------------
top10_300 <- crossed[power==300][order(cost_rank)][
  1:10, 
  .(frame, wheel, 
    "time"=ifelse(route==min(route),
                  sprintf("%02.f:%02.f         ",
                          route%/%60,
                          route%%60),
                  sprintf("%02.f:%02.f (+%02.f:%02.f)", 
                          route%/%60, 
                          route%%60, 
                          (route-min(route))%/%60,
                          (route-min(route))%%60)))]

top10_150 <- crossed[power==150][order(cost_rank)][
  1:10, 
  .(frame, wheel, 
    "time"=ifelse(route==min(route),
                  sprintf("%02.f:%02.f:%02.f         ",
                          route%/%3600,
                          route%%3600%/%60, 
                          route%%60),
                  sprintf("%02.f:%02.f:%02.f (+%02.f:%02.f)", 
                          route%/%3600,
                          route%%3600%/%60, 
                          route%%60, 
                          (route-min(route))%/%60,
                          (route-min(route))%%60)))]



# Plot costs -------------------------------------------------------------------
crossed[power!=900 & wheel!="Zwift 32mm Carbon" & frame!="Zwift Aero"] %>% 
  ggplot(aes(x=power, y=cost, colour=frame, shape=wheel)) +
  geom_path(alpha=0.5) +
  geom_point(size=2) +
  scale_y_reverse("Seconds Behind Fastest Bike") +
  scale_x_continuous("Power",
                     breaks=c(150, 225, 300),
                     labels=c("150W (2W/kg)", "225W (3W/kg)", "300W (4W/kg)")) +
  labs(colour="Frame", shape="Wheel") +
  theme_classic() ->
  crossover_plot



# Plot costs greyed out, focus on best at each power ---------------------------
crossed[power!=900 & frame!="Zwift Aero" & wheel!="Zwift 32mm Carbon" & best_rank!=1] %>% 
  ggplot(aes(x=power, y=cost, group=paste0(frame, wheel))) +
  geom_path(colour="#dddddd", alpha=0.5) +
  geom_point(colour="#dddddd", size=2) +
  scale_y_reverse("Seconds Behind Fastest Bike") +
  scale_x_continuous("Power",
                     breaks=c(150, 225, 300),
                     labels=c("150W (2W/kg)", "225W (3W/kg)", "300W (4W/kg)")) +
  labs(colour="Frame", shape="Wheel") +
  theme_classic() +
  # - add best performers in
  geom_path(data=crossed[power %in% c(150,300) & frame!="Zwift Aero" & wheel!="Zwift 32mm Carbon" 
                         & best_rank==1],
            aes(colour=frame), alpha=0.5) +
  geom_point(data=crossed[power %in% c(150,300) & frame!="Zwift Aero" & wheel!="Zwift 32mm Carbon" 
                          & best_rank==1],
             aes(colour=frame, shape=wheel), size=2) ->
  crossover_plot_greyed



# Plot frames only -------------------------------------------------------------
crossed[power!=900 & wheel=="ZIPP 454" & frame!="Zwift Aero",
        .(frame, wheel, "cost"=cost-min(cost, na.rm=TRUE)), by=power] %>% 
  ggplot(aes(x=power, y=cost, colour=frame)) +
  geom_path(alpha=0.5) +
  geom_point(size=2) +
  scale_y_reverse("Seconds Behind Fastest Frame") +
  scale_x_continuous("Power",
                     breaks=c(150, 225, 300),
                     labels=c("150W (2W/kg)", "225W (3W/kg)", "300W (4W/kg)")) +
  labs(colour="Frame") +
  theme_classic() ->
  crossover_plot_frames



# Plot wheels only -------------------------------------------------------------
crossed[power!=900 & frame=="Scott Addict RC" & wheel!="Zwift 32mm Carbon",
        .(frame, wheel, "cost"=cost-min(cost)), by=power] %>% 
  ggplot(aes(x=power, y=cost, colour=wheel)) +
  geom_path(alpha=0.5) +
  geom_point(size=2) +
  scale_y_reverse("Seconds Behind Fastest Wheel") +
  scale_x_continuous("Power",
                     breaks=c(150, 225, 300),
                     labels=c("150W (2W/kg)", "225W (3W/kg)", "300W (4W/kg)")) +
  labs(colour="Wheel") +
  theme_classic() ->
  crossover_plot_wheels






# Outputs
# top10_300
# top10_150
# crossover_plot
# ggsave("crossover.png", dpi=600, bg=NA, width=9, height=5)
# crossover_plot_greyed
# ggsave("crossover_focus.png", dpi=600, bg=NA, width=9, height=5)
# crossover_plot_frames
# ggsave("crossover_frames.png", dpi=600, bg=NA, width=9, height=5)
# crossover_plot_wheels
# ggsave("crossover_wheels.png", dpi=600, bg=NA, width=9, height=5)

