;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;A Housing Market Model
;;Anamaria Berea, Hoda Osman, Matt McMahon
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals 
[
housingDemand
]

; agents
breed [banks bank]
banks-own
[
myMortgages
incomeFromHouses
]

breed [people person]
people-own
[
  income    ; period income
  myHouses   ; which houses do I own; first in the list is the own I occupy. the rest are the ones I own and perhaps rent.
  timeInHouse ;
  investmentCapital
]

breed [houses house]
houses-own 
[
  has-owner
  updateMortgage
  is-occupied    ; does someone live here
  is-rental      ; am I a rental
  
  price  ; house price
  purchase-price;
  is-owned;todo keep track if house is owned or not
  mortgageCost  ; tick mortgage cost
  rent      ; tick rent cost
  
  missedPaymentCount ; count number of missed payments
]

breed [mortgages mortgage]
mortgages-own
[
  which-owner
  which-house
  which-bank
  
  purchasePrice
]

;initialization
to initialize
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  random-seed 8675309      
  ;agents
  setup-houses
  setup-people 
  
  setup-banks
  setup-mortgages
  
  ;plots
  setup-average-house-price-plot
  update-average-house-price-plot

  
  
 
end

to go
   
   update-housing-price-info    
   update-available-capital
   update-people
   buy-investment-houses
   update-available-capital   
   ;update-people
   update-mortgages   
   sell-investment-houses    
   tick
   
   update-average-house-price-plot
   update-mortgage-plot
   update-ownership-plot
   update-mortgageHousePrice-plot

   
   ;ask links [set hidden? not show-links]
   ;print [investmentCapital] of people 
   
    update-average-location
   ;update-housing-stats
   compute-bank-balances
   update-interest-rate-plot
   update-bankrupt-people-plot
   update-balance-sheet-plot
end


; procedures
to update-housing-price-info
  
    let tmpList []
    ask people
    [
      let tmpCount length myHouses 
      set tmpList fput tmpCount tmpList             
    ] 
    
    let multiplier 1 + 3 * (mean tmpList - housingDemand) / 10
   
    set housingDemand mean tmpList
    print word "housing multipler" multiplier
   
  
  ask houses
  [
    if random 100 < 5
    [ 
      ;if is-occupied = 0 ; todo: do this but make the adjustment only for un-owned houses.
      ;[
        set mortgageCost 0.01 +  price * interest-rate / 60
        set rent  price * rental-fraction
      ;]
    ]
       
    if random 100 < 20
    [  
        ;print word "1 " price
        set price (price * multiplier * multiplier * multiplier)
        ;print word "2 " price
    ]
   
  ifelse is-rental = 1
    [  
      set color rgb (55 + (200 * (price - min-price) / (max-price - min-price))) 0 0
    ]
    [
      set color rgb 0 0 (55 + (200 * (price - min-price) / (max-price - min-price)))
    ]  
  
  ifelse missedPaymentCount > 3
     [
         set size 2.0
         set color pink
         
     ]
     [
        ifelse is-rental = 1
       [  
         set color rgb (55 + (200 * (price - min-price) / (max-price - min-price))) 0 0
       ]
       [
         set color rgb 0 0 (55 + (200 * (price - min-price) / (max-price - min-price)))
       ]      
        set size 1.0
     ]
  ]
end

to sell-investment-houses
 ;ask people whose investment capital is negative to sell a house
 ask people with [investmentCapital < 0 and length myHouses > 1]
 [
   if random 100 < 50
   [
     ;sell a house 
     ;print "Selling a house"
     let tmpHouses but-first myHouses
     let listToSell houses with [member? self tmpHouses]   ; find houses that are in the person's list
     ;print listToSell
     ;print count houses with [updateMortgage = 1]
     let tmpMyHouses []
     set tmpMyHouses myHouses
     let foreclosedHouses  listToSell with [missedPaymentCount > 3]
     ifelse count foreclosedHouses > 0
     [
       if random-float 1.0 < 0.2
       [
        ask one-of foreclosedHouses
        [
         ;find my mortgage and sell me
         let myMortgage one-of mortgages with [which-house = myself] ; find my mortgage
         
         ;print myMortgage
         ;print tmpMyHouses
         set tmpMyHouses remove-item (position self  tmpMyHouses) tmpMyHouses
         ;set is-rental 0
         ;print tmpMyHouses
         ;some mortgages get asked to die which don't exist ...     
         ;ask myMortgage
         ;[
         ;die
         ;]        
         set missedPaymentCount 0   
         ]
       ]
     ]
     [
      ask one-of listToSell
      [
        ;find my mortgage and sell me
        let myMortgage one-of mortgages with [which-house = myself] ; find my mortgage
        
        ;print myMortgage
        ;print tmpMyHouses
        set tmpMyHouses remove-item (position self  tmpMyHouses) tmpMyHouses
        ;set is-rental 0
        ;print tmpMyHouses
        ;some mortgages get asked to die which don't exist ...     
        ;ask myMortgage
        ;[
        ;die
        ;]           
      ]
     ]
        ;print "Done Selling a house"
     set myHouses tmpMyHouses
   ]
 ]
end

to update-people
;ask people with [investmentCapital < 0]
;[
;set color pink
;set size 2 
;]
ask people with [investmentCapital >= 0]
[
set color rgb 0 (100 + (155 * (income - min-income ) / (max-income - min-income))) 0     
set size 1.0
]

  ask people
  [
    
    set timeInHouse (timeInHouse + 1)
    ;randomly move to a new house
    if (random mobility = 1 or ; check to see if it's time to move to a new hosue
          (investmentCapital < 0 and (length myHouses = 1))) ; or if house has become too expensive
    [
    ;;begin move to new house
      ;sell-house
      set timeInHouse 0
      let myHouse item 0 myHouses
  
      if ([is-rental] of myHouse = 0)
      [
        ;set [has-owner] of myHouse 0
        ask myHouse [set has-owner 0]
      ]
      ;set [is-occupied] of myHouse 0
      ask myHouse [set is-occupied 0]
      set myHouses remove-item 0 myHouses
      
      ;buy new house
          let housingList houses  with 
          [
            count people-here = 0         
          ];; assign a house to occupy

       let tmpHouse []
 
       let myRentalList housingList with [is-rental = 1 and rent < [income] of myself]
       let myPurchaseList housingList with [is-rental = 0 and mortgageCost < [income] of myself]
       
       ;print count myRentalList 
       ;print count myPurchaseList      
       
       
       ifelse (count myPurchaseList > 0)
       [
         set tmpHouse one-of myPurchaseList
       ]
       [
         if (count myRentalList > 0)
         [
            set tmpHouse one-of myRentalList
         ]     
       ]
       
      ;;occupy tmpHouse
      move-to tmpHouse     
      ;;create-link-with  tmpHouse          
      set myHouses  fput tmpHouse myHouses           ; add it to my list of houses. most people will have one house.      
 
      ask item 0 myHouses
      [
        set is-occupied 1
      ]      
    
     ;exchange mortgage

       ask mortgages with [which-owner = myself and which-house = myHouse]       
       [         
         set which-owner myself
        set which-house item 0 [myHouses] of which-owner
        set which-bank one-of banks
        move-to which-bank       
       ]  
    ]
    
    ;;end move to a new house
  ]  
end

to update-mortgages
  
  let tmpMortgageCount count houses with [updateMortgage = 1]
  create-mortgages tmpMortgageCount  
  [
    set which-house one-of houses with     
    [
      updateMortgage = 1
       ;member? self myHouses = true
    ]
    set which-owner one-of people with
    [
      member? [which-house] of myself myHouses = true
    ]       
    set which-bank one-of banks
    set purchasePrice [price] of which-house
    ;set [purchase-price] of which-house purchasePrice
    let newpp purchasePrice
    ask which-house [set purchase-price newpp]
    move-to which-bank
    ;set [updateMortgage] of which-house 0  ; finished updating
    ask which-house [set updateMortgage 0]
  ]
end

to update-available-capital
  ; update available capital
  ask people
  [
    let tmpCapital income
    let tmpHouse item 0 myHouses
    ifelse ([is-rental] of tmpHouse = 0)
    [
      set tmpCapital tmpCapital - [mortgagecost] of tmpHouse
    ]     
    [ 
     set tmpCapital tmpCapital - [rent] of tmpHouse
    ]
    if (length myHouses > 1)
    [
      let tmpHouses but-first myHouses
      ask houses with [member? self tmpHouses]   ; find houses that are in the person's list, and subtract cost
      [
        set tmpCapital tmpCapital - mortgageCost
        ifelse tmpCapital < 0
        [
          set missedPaymentCount (missedPaymentCount + 1)
        ]
        [
          set missedPaymentCount 0
        ]
      ]      
    ]
    set investmentCapital tmpCapital
  ]    
end

to buy-investment-houses
  ask people
  [    
    ;randomly choose a new house to buy
    if random-float 1.0 < 0.1
    [       
      ;print "buying an investment house" 
      ;buy new house
          let housingList houses  with 
          [
            count people-here = 0 and
            mortgagecost < [investmentCapital] of myself
          ];; assign a house to buy
       ;print [mortgagecost] of houses
       ;print investmentCapital
       let tmpHouse []
        
       ;let myPurchaseList housingList with [is-rental = 0 and mortgageCost < [income] of myself]      
       
       if (count housingList > 0)
       [
         set tmpHouse one-of housingList ;if there are houses available, choose one to buy
         ;;add house to my list
         ;print "tmpHouse"
         ;print tmpHouse
         set myHouses  lput tmpHouse myHouses           ; add it to my list of houses. most people will have one house.      
 
         ;adjust capital 
         ;set [is-rental] of tmpHouse 1    
         ask tmpHouse [set is-rental 1]     
         set investmentCapital (income - [mortgageCost] of tmpHouse)         
         
       ]
        ;print "done buying an investment house" 
    ]
  ]  
end

to setup-mortgages
  set-default-shape mortgages "circle"
  create-mortgages count houses with [is-occupied = 1]
  ask mortgages
  [
   let myHouse one-of houses with [is-occupied = 1 and updateMortgage = 1]
   set which-owner one-of people with     
   [
     item 0 myHouses = myHouse
   ]

    set which-house item 0 [myHouses] of which-owner
    set which-bank one-of banks
    set purchasePrice [price] of which-house
    ;set [updateMortgage] of which-house 0
    ask which-house [set updateMortgage 0]
    move-to which-bank
    set color green
  ]  
end

to setup-houses
 ask patches 
 [ 
   set pcolor black
 ]
 set-default-shape houses "house"
 ;set-default-shape patches "house"
 
  let houseCount ceiling (initial-density * world-width * world-height / 100)
  ;print houseCount
  create-houses houseCount
  ask houses 
  [
       set price (min-price + random (max-price - min-price))
       set is-occupied 0
       set mortgageCost 0.01 + price * interest-rate / 50
   
   if random-float 100.0 < rental-density
     [
       set is-rental 1
       set rent  price * rental-fraction
      
     ]
     let tmpPrice price
     move-to one-of patches with [count (houses-here) = 0 and abs (pycor / world-height - ((tmpPrice - min-price) / (max-price - min-price))) < .1]
     ;move-to one-of patches with [count (houses-here) = 0 ]
    ifelse is-rental = 1
    [  
      set color rgb (55 + (200 * (price - min-price) / (max-price - min-price))) 0 0
    ]
    [
      set color rgb 0 0 (55 + (200 * (price - min-price) / (max-price - min-price)))
    ]      
    set size 1 ; dont draw the house agent
    set updateMortgage 1
  ]

end

to setup-people 
  set-default-shape people "person"

  let num-people (count houses * percent-occupied / 100); 
  create-people num-people
    [ 
      set income (random (max-income - min-income) + min-income)
      set myHouses []
 
      
      let housingList houses  with 
          [
            count people-here = 0         
          ];; assign a house to occupy

      let tmpHouse []

      let myRentalList housingList with [is-rental = 1 and rent < [income] of myself]
      let myPurchaseList housingList with [is-rental = 0 and mortgageCost < [income] of myself]
      
      ;print count myRentalList 
      ;print count myPurchaseList      
      
      ifelse (count myPurchaseList > 0)
      [
        set tmpHouse one-of myPurchaseList
      ]
      [
        if (count myRentalList > 0)
        [
           set tmpHouse one-of myRentalList
        ]     
      ]
      
     ;;occupy tmpHouse
     move-to tmpHouse  ; here is where we should deal with homeless people  
     set timeInHouse random mobility
     ;;create-link-with  tmpHouse          
     set myHouses  lput tmpHouse myHouses           ; add it to my list of houses. most people will have one house.      

     ask item 0 myHouses
     [
       set is-occupied 1
     ]      
    ;adjust capital 
    let houseType [is-rental] of tmpHouse
    ifelse houseType = 1
    [
      set investmentCapital (income - [rent] of tmpHouse)
    ]
    [
      set investmentCapital (income - [mortgageCost] of tmpHouse)
    ]
    ;give self a color
    ;set color rgb 0 (100 + (155 * (income - min-income ) / (max-income - min-income))) 0     
    set color green
    ;set color scale-color green income min-income max-income
    ]    
end

to setup-banks
  set-default-shape banks "box"
  create-banks num-banks
    [
      set color yellow
      move-to one-of patches with 
        [count (turtles-here) = 0]
        set size 2
    ]
end

to compute-bank-balances
  ask banks
  [
  let delta 0
  ask mortgages with [which-bank = myself]
    [
     if [missedPaymentCount] of which-house > 0
     [
     set delta (delta + (([price] of which-house) - purchasePrice))
     ]
    ]
  print delta
  set incomeFromHouses delta
  ifelse (delta < 0)
   [
   set color red
   ] ; else
   [
   set color yellow
   ]
  ]
end
    





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;plots
to setup-average-house-price-plot
  set-current-plot "average house price"
  set-plot-y-range  0 (ceiling max [mortgageCost] of houses)
end

to update-average-house-price-plot 
  set-plot-y-range 50 150
  set-current-plot "average house price"
  let myMean mean [price] of houses with [is-occupied = 1]
  set-current-plot-pen "myMean"
  plot myMean
  print "mean house price" 
  print myMean
end

to update-mortgage-plot
  set-current-plot "average mortgage"
  let myMean mean [mortgageCost] of houses with [is-occupied = 1]
  set-current-plot-pen "myMean"
  plot myMean
  print "mean house price" 
  print myMean
end

to update-mortgageHousePrice-plot
  set-current-plot "Average House Price vs Average Mortgage"
  set-current-plot-pen "AverageHousePrice"
  plot mean [price] of houses with [is-occupied = 1] 
  set-current-plot-pen "AverageMortgage"
  plot mean [mortgageCost] of houses with [is-occupied = 1]
  
  ;print "mean house price" 
  ;print myMean
end

 
 to update-average-location
  set-current-plot "average loc"
  let myMean mean [ycor] of people
  set-current-plot-pen "myLoc"
  plot myMean
end

 to update-ownership-plot
   set-current-plot "owner occupied and rental homes"
   let myOwnedHouses count houses with [is-occupied = 1 and is-rental = 0]
   set-current-plot-pen "myOwnedHouses"
   plot myOwnedHouses
   let myRentedHouses count houses with [is-occupied = 1 and is-rental = 1]
   set-current-plot-pen "myRentedHouses"
   ;print "owned and rented"
   ;print word myOwnedHouses myRentedHouses
   plot myRentedHouses
 end
 
 to update-housing-stats
   set-current-plot "mean number of investment houses owned"
   set-plot-y-range  0 15
   let tmpList []
   ask people
    [
      let tmpCount length myHouses 
      set tmpList fput tmpCount tmpList 
    ] 
   print word "average houses owned:" mean tmpList
   set-current-plot-pen "count"
   plot (mean tmpList - housingDemand) * 10 
   ;plot (mean tmpList)
 end
 
  to update-interest-rate-plot
   set-current-plot "Interest Rate"
   set-plot-y-range  0 15

   plot interest-rate
   
  end
   
   to update-bankrupt-people-plot
   set-current-plot "percentage of people bankrupt"
   let bankruptPeopleCount (count people with [investmentCapital < 0]) / count people
  
   plot bankruptPeopleCount
    set-plot-y-range  0 11
   
   end
   
   to update-balance-sheet-plot
   set-current-plot "balance sheet plot"
   let solventBankCount count banks with [incomeFromHouses > 0]
  
   plot solventBankCount
    set-plot-y-range  0 50
   
   end
   
   
   
   
     
@#$#@#$#@
GRAPHICS-WINDOW
541
17
971
468
-1
-1
12.73
1
10
1
1
1
0
0
0
1
0
32
0
32
1
1
1
ticks
30.0

SLIDER
721
629
893
662
initial-density
initial-density
1
99
93.4
0.1
1
%
HORIZONTAL

BUTTON
19
39
121
72
NIL
initialize\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
3
208
107
246
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
130
209
234
247
run
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
22
11
172
29
Simulation Setup
14
0.0
1

SLIDER
723
670
895
703
rental-density
rental-density
0
100
20
1
1
%
HORIZONTAL

SLIDER
7
136
237
169
interest-rate
interest-rate
.25
15
7.25
0.25
1
%
HORIZONTAL

PLOT
242
18
524
229
average house price
NIL
NIL
0.0
10.0
50.0
150.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" ""
"myMean" 1.0 0 -16777216 true "" ""

SLIDER
722
710
894
743
percent-occupied
percent-occupied
0
100
44
1
1
%
HORIZONTAL

INPUTBOX
928
653
1083
713
min-price
75
1
0
Number

INPUTBOX
1032
653
1187
713
max-price
150
1
0
Number

INPUTBOX
1137
653
1224
713
max-income
100
1
0
Number

INPUTBOX
928
725
1023
785
num-banks
20
1
0
Number

INPUTBOX
1067
725
1161
785
rental-fraction
0.025
1
0
Number

PLOT
540
472
790
592
owner occupied and rental homes
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"myOwnedHouses" 1.0 0 -13345367 true "" ""
"myRentedHouses" 1.0 0 -2674135 true "" ""

INPUTBOX
1236
652
1321
712
min-income
10
1
0
Number

SLIDER
723
756
895
789
mobility
mobility
0
1200
76
1
1
NIL
HORIZONTAL

TEXTBOX
930
621
1080
641
Calibration Params
16
0.0
1

TEXTBOX
11
99
161
119
Run
16
0.0
1

PLOT
975
24
1135
467
average loc
NIL
NIL
0.0
10.0
0.0
32.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"myLoc" 1.0 0 -16777216 true "" ""

PLOT
252
237
513
357
average mortgage
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"myMean" 1.0 0 -16777216 true "" ""

PLOT
797
483
1063
603
Interest Rate
ticks
IR
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

TEXTBOX
641
587
1287
621
____________________________________________________________________________________________\n
11
0.0
1

PLOT
2
407
238
551
percentage of people bankrupt
x
count
0.0
0.0
0.0
11.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
0
259
235
402
balance sheet plot
NIL
NIL
0.0
0.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
249
377
524
556
Average House Price vs Average Mortgage
Time
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"AverageHousePrice" 1.0 0 -10899396 true "" ""
"AverageMortgage" 1.0 0 -2674135 true "" ""

@#$#@#$#@
## WHAT IS IT?

This model is an implementation of a simple, abstract housing market, with an adjustable interest rate. 

The goal is to look for the emergence of a “bubble” when a shock is introduced into the system and to understand how housing bubbles and foreclosures emerge. In this model, the shock is introduced via the interest rate variable. 

The hypothesis is that exogenous interest rate adjustments contribute to the rise in foreclosures and emergence of the housing “bubble”. 

## HOW TO USE IT

The main components of the model are People, Houses, Banks, and Mortgages. 

The ‘People’ agents are either renters or owners of one or more houses. Each house is associated with zero or one mortgage that is owned by a bank. As the principal agents in the model, people have annual fixed income that follows a uniform random distribution ranging between 5-15 K. The gradient green color of people reflects the differences in income level—the darker the shade, the wealthier the agent. At the initialization of the model, an agent evaluates whether it can buy a house as a primary residence. If the available investment capital is insufficient, it evaluates for renting a house instead. If it can afford to rent, it relocates to a random affordable rental, otherwise it exits the system. If the agent can afford to buy a primary residence house, it relocates to one. If a house owner can not afford paying mortgages on the house, it evaluates for renting. House owner systematically evaluate whether they can afford buying an extra house for investment (renting out for other agents). Moreover, if an agent owns more than one house and can no longer afford paying the mortgages, it randomly picks a house from the list of houses it owns and sells it. Lastly, the expected time for staying in the same house is set at 7 years (84 ticks during the run of simulation); i.e. agents move every 7 years on average.

The ‘House’ agents have prices that follow a random uniform distribution within the range of 75-150K. Red patches indicate rental houses, while blue ones are for ownership. Again, darker shades of either color indicate higher mortgage cost or rent. Black patches are assigned as empty. A house put on sale turns into pink as an indication of foreclosure.

‘Mortgages’ are formulated as agents to capture object-oriented notion that a mortgage is an entity unto itself:  the mortgage is owned by (and housed within) a bank, yet is associated with a particular person and also with a particular house.

‘Banks’ are agents that own balance sheets, introduced to keep track of their assets and liabilities. The liabilities side of the balance sheets comprises the whole mortgage value of the houses owned by a bank. Banks assets, on the other hand, include monthly mortgage payments investments returns that are assumed to be exogenous to the model (for simplicity). Consequently, in case of a house foreclosure, the owner bank is negatively affected on the side of its assets.

The model is initiated by creating houses at a specified density on the map (using ‘Initial density of patches’ parameter). Each house is then assigned a price within the specified range. Based on the ‘Rental House Density’ parameter, a fraction of houses are assigned as rentals. ‘Percent occupied’ parameter determines the number of initialized people on landscape. Each person is then assigned an income level within the specified range. People are assigned to houses by matching their income and mortgage cost/rent level.

Fluctuate the interest rate and observe the foreclosures - as pink houses - in the landscape. The model can be adjusted for verisimilitude via the calibration parameters. 

The average house price, the mortgage and the balance sheets are the most important plots. Their variations relative to each other (one high, the other low) show whether a crisis emerges or not.

## THINGS TO NOTICE

At default, the people move between houses, houses are being bought and sold and renters become owners and vice-versa. There are some foreclosures, but not too many. By keeping the interest rate parameter constant, the system stabilizes until no house is being sold any more and there is only movement of people between the houses. 

The only parameter in this model is the interest rate.  By increasing or decreasing the interest rate based on real time values (1 tick = 1 month), the system shows a spike in foreclosures followed by adjustments. The model shows, through the rental/ownership ratio, that less people afford more houses and the people with higher income that afford more houses and offer them for rent.

## NETLOGO FEATURES

This code has been updated to comply with Netlogo 5.0.4 (The previous version used deprecated Netlogo 4.0.4 features, per http://ccl.northwestern.edu/netlogo/docs/transition.html)

## CREDITS AND REFERENCES

We thank the Center for Social Complexity at George Mason University, USA.

Model Web Site: http://www.css.gmu.edu/node/81
Paper: http://www.css.gmu.edu/images/HousingMarket_revisited/Housing_Market_revisited.pdf
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.4
@#$#@#$#@
setup-random repeat 20 [ go ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
