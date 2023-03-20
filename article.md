*Which is the best bike for this route?* is not the (only) question you
should be asking
================

- Importance of bike choice; racing, chasing PRs, KOMs and sprints
- Resource of ZwiftInsider speed test data and derivatives (e.g. my data
  browser, ZwifterBikes)
  - Details of testing
  - Judging routes, might expect fairly aero setup to do well even on
    fairly climb heavy routes like Mountain Route (survey?)

``` r
all_bikes[power==300][
  order(route),
  .("Frame"=frame, "Wheel"=wheel, "Time"=
      sprintf("%02.f:%02.f (+% 2s)",
              route%/%60, route%%60, as.character(route-min(route))))][
  1:10]
```

    ##                          Frame                        Wheel        Time
    ##  1:  Specialized Venge S-Works DT Swiss ARC 1100 DiCut Disc 54:00 (+ 0)
    ##  2:            Scott Addict RC DT Swiss ARC 1100 DiCut Disc 54:05 (+ 5)
    ##  3:         Canyon Aeroad 2021 DT Swiss ARC 1100 DiCut Disc 54:05 (+ 5)
    ##  4:                       TRON                         TRON 54:05 (+ 5)
    ##  5: Specialized Aethos S-Works DT Swiss ARC 1100 DiCut Disc 54:09 (+ 9)
    ##  6:  Specialized Venge S-Works                 ENVE SES 7.8 54:09 (+ 9)
    ##  7:  Specialized Venge S-Works                     ZIPP 808 54:13 (+13)
    ##  8:  Specialized Venge S-Works                     ZIPP 454 54:13 (+13)
    ##  9:            Scott Addict RC                 ENVE SES 7.8 54:14 (+14)
    ## 10:         Canyon Aeroad 2021                 ENVE SES 7.8 54:14 (+14)

- But ZI tests performed using a very specific profile of rider; 300w,
  182cm, 75kg
  - This doesn’t match all riders on Zwift
  - Varying rider power/power-to-weight ratio should change the relative
    importance of aerodynamic performance and climbing performance, with
    slow riding placing a great emphasis on climbing performance
  - This means judging which bike is best for a given route is not just
    about how much climbing occurs on a route, but also needs to
    incorporate the profile of the rider
- To test how rider power/power-to-weight affects performance and
  recommended frame and wheel choice, I used a bot to test performance
  of a 182cm, 75kg rider riding at 300W (4W/kg) and 150W (2W/kg)
  - I did this test on Watopia’s Mountain Route as a more representative
    route; it has some flat, some mixed difficulty of climbing and some
    descents
  - ZI tests were on very extreme routes, either completely flat or
    steep climbing (so should be less sensitive to rider variation)
  - Frame and wheel performance is independent, so wheels were tested on
    a Zwift Aero frame and frames tested with Zwift 32mm Carbon wheels,
    and frame and wheel effects used to get predicted times for each
    unqiue combination
    - These predicted times were verified for a random selection of
      bikes

``` r
all_bikes[power==150&frame=="Zwift Aero"][
  order(route),
  .("Wheel"=wheel, "Time Behind (s)"=route-min(route))]
```

    ##                           Wheel Time Behind (s)
    ## 1:   DT Swiss ARC 1100 DiCut 62               0
    ## 2:                 ENVE SES 7.8               2
    ## 3: DT Swiss ARC 1100 DiCut Disc               5
    ## 4:                 ENVE SES 3.4               7
    ## 5:                     ZIPP 454               8
    ## 6:                     ZIPP 808              10
    ## 7:      Lightweight Meilenstein              18
    ## 8:            Zwift 32mm Carbon              45

``` r
all_bikes[power==300&frame=="Zwift Aero"][
  order(route),
  .("Wheel"=wheel, "Time Behind (s)"=route-min(route))]
```

    ##                           Wheel Time Behind (s)
    ## 1: DT Swiss ARC 1100 DiCut Disc               0
    ## 2:                 ENVE SES 7.8               9
    ## 3:                     ZIPP 808              13
    ## 4:                     ZIPP 454              13
    ## 5:   DT Swiss ARC 1100 DiCut 62              14
    ## 6:                 ENVE SES 3.4              16
    ## 7:      Lightweight Meilenstein              28
    ## 8:            Zwift 32mm Carbon              44

``` r
all_bikes[power==150&frame=="Zwift Aero"][
  order(epic),
  .("Wheel"=wheel, "Time Behind (s)"=epic-min(epic))]
```

    ##                           Wheel Time Behind (s)
    ## 1:      Lightweight Meilenstein               0
    ## 2:                 ENVE SES 3.4               2
    ## 3:   DT Swiss ARC 1100 DiCut 62               2
    ## 4:                     ZIPP 454               3
    ## 5:                 ENVE SES 7.8               4
    ## 6:                     ZIPP 808               9
    ## 7:            Zwift 32mm Carbon              13
    ## 8: DT Swiss ARC 1100 DiCut Disc              13

``` r
all_bikes[power==300&frame=="Zwift Aero"][
  order(epic),
  .("Wheel"=wheel, "Time Behind (s)"=epic-min(epic))]
```

    ##                           Wheel Time Behind (s)
    ## 1:   DT Swiss ARC 1100 DiCut 62               0
    ## 2: DT Swiss ARC 1100 DiCut Disc               2
    ## 3:                     ZIPP 454               2
    ## 4:                 ENVE SES 7.8               2
    ## 5:                 ENVE SES 3.4               3
    ## 6:      Lightweight Meilenstein               4
    ## 7:                     ZIPP 808               4
    ## 8:            Zwift 32mm Carbon              11
