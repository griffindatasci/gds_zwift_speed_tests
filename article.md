Which bike is quickest up the alp?
================

The Specialized Aethos S-Works and Lightweight Meilenstein wheels,
right? Nope, it’s the Cadex Tri TT frame with DT Swiss ARC 1100 DiCut
Disc wheels of course. No really, that’s the quickest. At least, it’s
the quickest *if* you weigh 50 kg and can knock out 2000 Watts for 10
minutes — it’s 26 seconds (\>4%) quicker than the Aethos setup. Ok, I
accept that not many of us are quite doing those numbers, but the point
stands. **The quickest bike over a route is not *just* about the route,
but also about the rider.**

Bike choice is important to get right for racers, PR chasers and KQOM
hunters, where margins of mere seconds make all the difference. Go into
any article about a route on Zwift, Zwift Facebook group or forum and
you’ll quickly find plenty of questions asking *which bike for this
route?* The answers always boil down to balancing the relative needs for
aerodynamic and climbing performance given the profile of the route, but
few — if any — discuss the profile of the rider.

### Why does rider profile matter?

There are several forces affecting a rider, but the important one to
consider here is aerodynamic drag — it increases exponentially with
speed, while the other forces slowing the rider increase linearly. This
means that, as speed increases, so too does the relative importance of
aerodynamic performance. If a rider is going up a 5% slope at 50 Watts,
aerodynamic drag is a tiny part of the forces the rider is overcoming to
move forward, but if that rider is going up at 500 Watts then
aerodynamic is going to be a very large component. If aerodynamic drag
is a big component of the forces slowing you down, then there are
potentially big gains to minimizing it. Likewise, if it’s a tiny
component, then there is less to be gained by reducing aerodynamic drag.

### The Experiment

With this idea in mind, I set out to perform an experiment. The aim was
to test how rider profile affects bike choice. I chose to set up riding
around the Mountain Route in Watopia. I chose this route for a few
reasons:

1.  While the Tempus Fugit and Alpe du Zwift tests shed light on
    performance at the extreme ends of the scale, that also means
    differences in relative performance are not likely to change outside
    of extreme conditions (e.g. 2000 Watts at 40 W/kg)
2.  Mountain route is not just flat or just uphill, but more
    representative of routes available in Zwift
3.  Mountain route contains flat sections (from start to KOM), rolling
    sections (Villas and Esses), a moderate pitch climb (Epic) and a
    steep climb (Radio Tower) and their descents, allowing me to focus
    in on those areas and compare performance across those route profile
    types

My rider, a bot — Robot Griffin — is strikingly similar to the
ZwiftInisder bot. Both are 182 cm tall, weigh in at 75kg, can happily
push 300 Watts (4 W/kg) for an hour, and like to ride behind a firewall
to take away drafting and stop ruining leaderboards. Unlike the
ZwiftInsider bot, Robot has also added in some zone two training (it’s
all the rage) and will happily plod along at 150 Watts (2 W/kg).

But Robot is also time-pressed father of three and couldn’t possibly
test all frames and wheelsets, so he picked a few of the tried and
tested standout performers. Along with the TRON, he rode the Specialized
Venge S-Works and Aethos S-Works, Scott Addict RC, Canyon Aeroad 2021,
Focus Izalco Max, Pinarello Dogma F and Zwift Aero frames (all on Zwift
32mm Carbon wheels) and DT Swiss ARC 1100 DiCut Disc and 62, ZIPP 808
and 454, ENVE SES 3.4 and 7.8, and Lightweight Meilenstein wheels (all
on the Zwift Aero frame). Because frame and wheel performance is
independent, these data can be worked to give accurate predictions of
times for every combination of frame and wheel, giving times for 57
different bikes, each tested at 150 Watts and 300 Watts.

### The Results

First up, let’s look at the results at 300 Watts — the same conditions
as run in the ZwiftInsider speed tests. Beforehand, just based on
judgement of route profile and the ZwiftInsider speed tests, I would
have picked a bike like the TRON or an all-rounder like a Scott Addict
RC with ZIPP 454s. I even did a sneaky survey of the Zwift Riders
Facebook group and among ten well suited bikes, the TRON was the
standout favourite with 72 of the 110 votes, and the Aethos with
Lightweight Meilensteins came in second with 20 votes. Surprisingly,
only 1 of the 110 voters picked the fastest bike (at 300 Watts) — the
Specialized Venge S-Works frame and DT Swiss ARC 1100 DiCut Disc
wheelset!

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
    ##  4:          Pinarello Dogma F DT Swiss ARC 1100 DiCut Disc 54:05 (+ 5)
    ##  5:                       TRON                         TRON 54:05 (+ 5)
    ##  6: Specialized Aethos S-Works DT Swiss ARC 1100 DiCut Disc 54:09 (+ 9)
    ##  7:           Focus Izalco Max DT Swiss ARC 1100 DiCut Disc 54:09 (+ 9)
    ##  8:  Specialized Venge S-Works                 ENVE SES 7.8 54:09 (+ 9)
    ##  9:  Specialized Venge S-Works                     ZIPP 808 54:13 (+13)
    ## 10:  Specialized Venge S-Works                     ZIPP 454 54:13 (+13)

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
