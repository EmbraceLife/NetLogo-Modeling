;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;A Housing Market Model
;; updated, modified and heavily commented by 深度碎片
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; originally written by Anamaria Berea, Hoda Osman, Matt McMahon
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extensions [palette]

globals
[
housingDemand  ;; demand for houses
]

breed [banks bank]  ;; create a breed called banks, its singular form is named bank

banks-own          ;; banks properties
[
  myMortgages       ;; a bank's mortgages offer to customers

  incomeFromHouses  ;; a bank's income from those houses
]

breed [people person]  ;; create a breed named people, its singluar form is named person

people-own           ;; people have properties
[
  income             ;; every person has income (Housing 2009 model, owners have income and every tick updated with shock up, down or inflation )

  myHouses           ;; houses a person own or rent

  timeInHouse        ;; time or ticks for living in the house

  investmentCapital  ;; how much capital does a person have for investment

]

breed [houses house]  ;; create a breed named houses, and a singluar form is named house

houses-own            ;; all houses have the following properties
[
  has-owner           ;; whether the house has an owner or not ????

  updateMortgage      ;; whether to update mortgage or not ????

  is-occupied         ;; does someone live here or not ????

  is-rental           ;; am I a rental or not ????

  price               ;; house price

  purchase-price      ;; price at which price bought

  is-owned            ;; whether house is owned or not

  mortgageCost        ;; mortgage cost at each tick

  rent                ;; rent cost at each tick

  missedPaymentCount  ;; count number of missed payments on a house
]

breed [mortgages mortgage]  ;; create a breed named mortgages, and the singular form is named mortgage

mortgages-own         ;; all mortgages have the following properties
[
  which-owner         ;; a mortgage has its owner

  which-house         ;; a mortgage has its house

  which-bank          ;; a mortgage has its bank

  purchasePrice       ;; a mortgage has its house purchase price
]


to setup

  clear-all            ;; wipe out the world

  random-seed 8675309  ;; set a random seed for reproducibility, but why this particular random seed, and if this is special, then how did we find it?????

  if exp-options = "base line"    ;; set parameters as original author want the model to be
  [
    set interest-rate 7.25        ;; 7.25% interest rate per year
    set initial-density 93.4      ;; 93.4% land have houses
    set rental-density 20         ;; 20% houses are for rental
    set percent-occupied 44       ;; 44% of houses are occupied by people
    set mobility 84               ;; provide a random number for timeInHouse
    set min-price 75              ;; minimum house price
    set max-price 150             ;; maximum house price
    set max-income 100            ;; maximum household income
    set min-income 10             ;; minimum household income
    set num-banks 20              ;; num of banks
    set rental-fraction 0.025     ;; rental price = price * rental-fraction
  ]

  setup-houses         ;; setup for houses (all houses now need a mortgage)

  setup-people         ;; setup for people (nothing to do with updateMortgage)

  setup-banks          ;; setup for banks  (nothing to do with updateMortgage)

  setup-mortgages      ;; setup for mortgages (all houses get a mortgage)

  setup-average-house-price-plot  ;; setup the plotting for average house price

  update-average-house-price-plot  ;; update the plotting for average house price

  reset-ticks          ;; put clock back to 0

end

to go

   update-housing-price-info            ;; update house price info

   update-available-capital             ;; update available capital

   update-people                        ;; update people

   buy-investment-houses                ;; with excess capital to buy a new house to let

   update-available-capital             ;; update capital again

   update-mortgages                     ;; mortgage update

   sell-investment-houses               ;;

   tick

   update-average-house-price-plot
   update-mortgage-plot
   update-ownership-plot
   update-mortgageHousePrice-plot

   update-average-location
   ;update-housing-stats
   compute-bank-balances
   update-interest-rate-plot
   update-bankrupt-people-plot
   update-balance-sheet-plot
end



to update-housing-price-info

    let tmpList []

    ask people                                                  ;; ask each person
    [
      let tmpCount length myHouses                              ;; count how many houses the person rent or own

      set tmpList fput tmpCount tmpList                         ;; put the count-number `tmpCount` into the list `tmpList`
    ]

    let multiplier 1 + 3 * (mean tmpList - housingDemand) / 10  ;; multiplier ??? : mean tmpList = average house a person occupies

    set housingDemand mean tmpList                              ;; set housingDemand to be the average house a person occupies

;    print word "housing multipler" multiplier                  ;; plot multiplier later


  ask houses                                                    ;; ask each house
  [
    if random 100 < 5                                           ;; for 5 % of time
    [
      ;if is-occupied = 0 ; todo: do this but make the adjustment only for un-owned houses.
      ;[
        set mortgageCost 0.01 +  price * interest-rate / 60     ;; update mortgageCost for the house, by reducing the cost a little, previously /50, not /60

        set rent  price * rental-fraction                       ;; rent stays the same
      ;]
    ]

    if random 100 < 20                                          ;; for 20 % of time
    [

        set price (price * multiplier * multiplier * multiplier)  ;; update its price by triple multiplier

    ]

  ifelse is-rental = 1                                           ;; if this house is for rental, make it red scale by price
    [
      set color rgb (100 + (155 * (price - min-price) / (max-price - min-price))) 0 0
    ]
    [                                                            ;; if this house is bought, make it green scale by price
      set color rgb 0 (100 + (155 * (price - min-price) / (max-price - min-price))) 0
    ]
    set color lput 120 color                                 ;; add transparency to houses, current 120 is the best value for display



  ifelse missedPaymentCount > 3                                  ;; if miss payment is more than 3 times, make it bigger and pink
     [
         set size 2.0
         set color pink
         set color extract-rgb color
         set color lput 135 color                                 ;; add transparency to houses, current 120 is the best value for display

     ]
     [                                                           ;; if missedPaymentCount <= 3, put the house color and size back to normal
        ifelse is-rental = 1
       [
          set color rgb (100 + (155 * (price - min-price) / (max-price - min-price))) 0 0
       ]
       [
          set color rgb 0 (100 + (155 * (price - min-price) / (max-price - min-price))) 0
       ]
        set size 1.0
        set color lput 120 color                                 ;; add transparency to houses, current 120 is the best value for display
     ]


  ]
end

to sell-investment-houses

 ask people with [investmentCapital < 0 and length myHouses > 1]       ;; ask people whose investment capital are negative and has more tha 1 house, ask each person
 [
   if random 100 < 50                                                  ;; randomly select 50% of people (not all of them)
   [
     let tmpHouses but-first myHouses                                  ;; get all but first of myHouses, assigned to tmpHouses

     let listToSell houses with [member? self tmpHouses]               ;; get all the houses above into agent-set rather than a list, assign to listToSell (agent-set)

     let tmpMyHouses []                                                ;; local var tmpMyHouses

     set tmpMyHouses myHouses                                          ;; assign myHouses to tmpMyHouses

     let foreclosedHouses  listToSell with [missedPaymentCount > 3]    ;; get those houses inside listToSell, which has more than 3 missedPayments, assign to foreclosedHouses

     ifelse count foreclosedHouses > 0                                 ;; if foreclosedHouses do exist
     [
       if random-float 1.0 < 0.2                                       ;; randomly select 20% of them
       [
        ask one-of foreclosedHouses                                    ;; ask one of the foreclosedHouses
        [

         let myMortgage one-of mortgages with [which-house = myself]   ;; get one of the mortgages whose house is the foreclosedHouse, assign to myMortgage

         set tmpMyHouses remove-item (position self  tmpMyHouses) tmpMyHouses ;; remove the foreclosedhouse from tmpMyHouses list

;         set is-rental 0                                               ;; set the foreclosedHouse to be bought by someone
;
;         ask myMortgage [ die ]                                        ;; ask the foreclosedHouse's mortgage to die  *********** problematic *****************

         set missedPaymentCount 0                                      ;; set the foreclosedHouse's missedPaymentCount to 0

         ]
       ]
     ]
     [
      ask one-of listToSell                                            ;; if foreclosedHouses don't exist, ask one of the listToSell houses
      [
        ;find my mortgage and sell me
        let myMortgage one-of mortgages with [which-house = myself]    ;; get one of the mortgages which belongs to the house

        set tmpMyHouses remove-item (position self  tmpMyHouses) tmpMyHouses  ;; remove the house from tmpMyHouses

;        set is-rental 0
;
;        myMortgage [ ask myMortgage [ die ] ]                          ;; ask the foreclosedHouse's mortgage to die  *********** problematic *****************

      ]
     ]

     set myHouses tmpMyHouses                                          ;; now update myHouses for the person (mortgage die, the house is no longer the person's )
   ]
 ]
end



to update-people

  ask people with [investmentCapital < 0]                         ;; ask people with negative capital
  [
    set color pink                                                ;; make them pink and bigger
    set size 2
  ]

  ;; [ check : color people by income ]
  ask people with [investmentCapital >= 0]                         ;; ask people who still have positive capital after renting or buying
  [
    ;  set color rgb 0 (100 + (155 * (income - min-income ) / (max-income - min-income))) 0

    ;; [ check people income level by color ]
    set color palette:scale-scheme "Divergent" "Spectral" 4  income  min-income  max-income
    ;; divide people into 4 colors according to their income range
    ;; income color : red=smallest, yellow = small, green = medium, blue = large

    set size 1.0
  ]

  ask people
  [
    ;; [ check : when to move houses : 1/84 chance or no money to pay rent or mortgage ]
    set timeInHouse (timeInHouse + 1)                              ;; count the period the person occupies its house

    if (; timeInHouse = mobility or                                ;; no person stay in a house more than 84 ticks (maybe too strict than the original code below)

        random mobility = 1 or                                     ;; if 1/mobility chance occurred or (meaning only stay in the house for 7 years = 84 ticks )

        (investmentCapital < 0 and (length myHouses = 1)))         ;; or the person has just one house but investmentCapital is negative
    [

      set timeInHouse 0                                            ;; set the period to stay in the house to be 0 (meaning leaving the house)

      ;; [ check : house is sold due to time or lack of money]
      let myHouse item 0 myHouses                                  ;; get the house the person lives in (just one house in total)

      if ([is-rental] of myHouse = 0)                              ;; if the person is the owner of the house
      [

        ask myHouse [set has-owner 0]                              ;; ask the house to be one without an owner
      ]

      ask myHouse [set is-occupied 0]                              ;; ask the house to be empty (not occupied)

      set myHouses remove-item 0 myHouses                          ;; this house is no longer on myHouses list

      if investmentCapital < 0 and (length myHouses = 1) [ die ]   ;; ************** added ****************
                                                            ;; if the person has no positive capital with one house, no way for him to rent neither, the person has to exit

      let housingList houses  with                                 ;; get all the empty houses
        [
          count people-here = 0
        ]

       let tmpHouse 0                                             ;; temporal house variable 0

       let myRentalList housingList with [is-rental = 1 and rent < [income] of myself]  ;; find empty houses which are for rental and the person can afford to rent

       let myPurchaseList housingList with [is-rental = 0 and mortgageCost < [income] of myself] ;; find empty houses which are for sale and the person can afford mortgage

       ifelse (count myPurchaseList > 0)                           ;; choose to a to-buy-house first
       [
         set tmpHouse one-of myPurchaseList                        ;; make it tmpHouse
       ]
       [
         if (count myRentalList > 0)                               ;; if not, choose a to-rent-house
         [
            set tmpHouse one-of myRentalList                       ;; make it tmpHouse
         ]
       ]

      move-to tmpHouse                                              ;; let the person move into the house (either to-buy or to-rent )

      ;;create-link-with  tmpHouse              maybe
      set myHouses  fput tmpHouse myHouses                          ;; put this house in the first row of myHouses

      ask item 0 myHouses                                           ;; get this house again
      [
        set is-occupied 1                                           ;; set it to be occupied
      ]


      ;; if the person owns the house but time up has to move out find new houses, old mortgage has to transform into a new mortgage of the same person
     ask mortgages with [which-owner = myself and which-house = myHouse]  ;; get the person's previous house's mortgage, myHouse is the person's previous house defined above
     [
       set which-owner myself                                             ;; owner of the mortgage stays the same

      set which-house item 0 [myHouses] of which-owner                    ;; get the first house on the person's myHouses to be the mortgage house

      set which-bank one-of banks                                         ;; choose a random (new) bank for the mortgage

      move-to which-bank                                                  ;; move the mortgage to the bank
     ]
    ]
  ]
end


to update-mortgages

  let tmpMortgageCount count houses with [updateMortgage = 1]    ;; get all houses whose mortgage can be updated, assign to tmpMortgageCount

  create-mortgages tmpMortgageCount                              ;; create equal number of mortgages with those houses above ( tmpMortgageCount ), ask each mortgage

  [
    set which-house one-of houses with                           ;; get a random house from the group above, assign to `which-house` of the mortgage
    [
      updateMortgage = 1
    ]

    set which-owner one-of people with                           ;; get one of the people whose myHouses has the mortgage house, assign to which-owner
    [
      member? [which-house] of myself myHouses = true            ;; myself is mortgage, use the house to locate the owner of the house
    ]

    set which-bank one-of banks                                  ;; get a random bank

    set purchasePrice [price] of which-house                     ;; get the `price` of the house, assign to purchasePrice

    ;set [purchase-price] of which-house purchasePrice
    let newpp purchasePrice                                      ;; save the price to a local var

    ask which-house [set purchase-price newpp]                   ;; save the price to `purchase-price` of the house

    move-to which-bank                                           ;; move mortgage to the bank

    ask which-house [set updateMortgage 0]                       ;; ask the house to stop updateMortgage
  ]

end


to update-available-capital

  ask people                                                     ;; ask each person
  [
    let tmpCapital income                                        ;; let income to be tmpCapital

    let tmpHouse item 0 myHouses                                 ;; get the first house of myHouses to be tmpHouse  (distinguish rent or own in the following )

    ifelse ([is-rental] of tmpHouse = 0)                         ;; if the tmpHouse is not rental but owned
    [
      set tmpCapital tmpCapital - [mortgagecost] of tmpHouse     ;; update tmpCapital by subtract mortgageCost
    ]
    [
     set tmpCapital tmpCapital - [rent] of tmpHouse              ;; if the tmpHouse is rental, then update tmpCapital by subtracting rent
    ]
    if (length myHouses > 1)                                     ;; if there are more than 1 house in myHouses
    [
      let tmpHouses but-first myHouses                           ;; get the houses except the first one

      ask houses with [member? self tmpHouses]                   ;; ask each of the tmpHouses
      [
        set tmpCapital tmpCapital - mortgageCost                 ;; update tmpCapital by subtract mortgageCost

        ifelse tmpCapital < 0                                    ;; if tmpCapital is negative, meaning this time the person didn't pay mortgage in full
        [
          set missedPaymentCount (missedPaymentCount + 1)        ;; add 1 up to missedPaymentCount
        ]
        [
          set missedPaymentCount 0                               ;; if tmpCapital is positive, no problem with mortgage payment this time
        ]
      ]
    ]
    set investmentCapital tmpCapital                             ;; update tmpCapital to investmentCapital
  ]
end


;; [ check : buy a second house for renting ]
to buy-investment-houses

  ask people                                                      ;; ask each person
  [

    if random-float 1.0 < 0.1                                     ;; only for the 10% of chance or time or 10% of people are selected randomly
    [

      let housingList houses  with                                ;; find the person all empty houses with affordable mortgages, assign to housingList
      [
        count people-here = 0 and

        mortgagecost < [investmentCapital] of myself
      ]

       let tmpHouse []

       if (count housingList > 0)                                 ;; if such house exist, ( it does not matter whether this house was for rental before)
       [
         set tmpHouse one-of housingList                          ;; take a random house from the group of houses

         set myHouses  lput tmpHouse myHouses                     ;; add this new house to the end of myHouses


         ask tmpHouse [set is-rental 1]                           ;; make this house a rental house

         set investmentCapital (income - [mortgageCost] of tmpHouse)  ;; calc the remaining investmentCapital

       ]

    ]
  ]
end

to setup-mortgages

  set-default-shape mortgages "circle"                                      ;; all mortgages are circle shapes

  create-mortgages count houses with [is-occupied = 1]                      ;; create as many mortgages as the occupied houses ( include rented and purchased houses)

  ask mortgages  ;; ask each mortgage to
  [
   let myHouse one-of houses with [is-occupied = 1 and updateMortgage = 1]  ;; take a random house which is occupied and whose mortgage needs update

   set which-owner one-of people with                                       ;; get the person who has the house (rent or own it ? ), assign to which-owner
   [
     item 0 myHouses = myHouse
   ]

    set which-house item 0 [myHouses] of which-owner                        ;; get the house of the person (equal to myHouse), assign to which-house

    set which-bank one-of banks                                             ;; get one of the banks, assign to which-bank

    set purchasePrice [price] of which-house                                ;; get the price of the house, assign to `purchasePrice` of the mortgage

    ask which-house [set updateMortgage 0]                                  ;; ask the house to stop update mortgage, so that next mortgage won't take the same house again

    move-to which-bank                                                      ;; move mortgage to the bank

    set color green                                                         ;; color the mortgage green

  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; paint land, create certain % of land to be houses, set house price with gradient, nobody lives in (occupied) for now,
;; calc mortgage cost, make certan % houses for rental, set rental price, localize houses according to prices top high bottom low;
;; rental houses are red, low price dark, high price bright ; non-rental (purchased) houses are blue, low price dark blue, high price bright blue
;; house size to be 1, mortgage are allowed to be updated now ???

to setup-houses


  ;; [ check empty land ] empty land are black
  ask patches  ;; ask each patch or land
 [
    if land-color = "black" [ set pcolor 0 ]                  ;; paint land black (right now seems better than gray )

    if land-color = "gray" [ set pcolor 5 ]
 ]


  set-default-shape houses "house"                            ;; use "house" as default shape for all houses


  ;; [ check house number ] The model is initiated by creating houses at a specified density on the map (using ‘Initial density of patches’ parameter)
  let houseCount ceiling (initial-density * world-width * world-height / 100)
                                                              ;; get the number of houses to be created

  create-houses houseCount                                    ;; create houses to the same number above

  ask houses                                                  ;; ask each house to do the following
  [

       ;; [ check house price ] Each house is then assigned a price within the specified range.
       set price (min-price + random (max-price - min-price)) ;; give each house a random price between min and max prices

       set is-occupied 0                                      ;;  make is-occupied 0 , not yet rented or bought

       set mortgageCost 0.01 + price * interest-rate / 50     ;; calc this house mortgageCost

       ;; [ check rentals with price ] Based on the ‘Rental House Density’ parameter, a fraction of houses are assigned as rentals. The rest is owned houses.
       if random-float 100.0 < rental-density                 ;; randomly set rental-density % of houses for rental
       [
          set is-rental 1                                     ;; is-rental as 1

          set rent  price * rental-fraction                   ;; make rental price, to be price * rental-fraction
       ]

       let tmpPrice price                                     ;; save the house price to temporary price

       ;; [ check house locations ] all houses are located on y-axis parallel to prices (top with high price, bottom with low price)
       move-to one-of patches with                            ;; move the house to one of the empty patches/land
       [
            count (houses-here) = 0 and                       ;; the patches have no houses on it

            abs (pycor / world-height - ((tmpPrice - min-price) / (max-price - min-price))) < .1  ;; higher the land, expensive the house; vice verse
                                                                                                  ;; allow maximum 10% variation
                                                                                                  ;; it requires the world origin to be at the bottom left
       ]


    ;; [ check house colors ] rental houses are red, brighter color is high price; owned houses are blue, brighter color is high price
       ifelse is-rental = 1                                    ;; if the house is for rental

       [
          set color rgb (100 + (155 * (price - min-price) / (max-price - min-price))) 0 0
                                                               ;; make min price light red 55 and max price dark red 55 + 200, everything between

         ;; set color palette:scale-scheme "Divergent" "RdYlGn" 3  price  min-price max-price
       ]
       [
          set color rgb 0 (100 + (155 * (price - min-price) / (max-price - min-price))) 0
                                                               ;; if house for purchase, make min-price light blue 55, max-price dark blue 55

         ;; set color palette:scale-scheme "Divergent" "RdYlGn" 5  price  min-price max-price  ;; RdGy, RdYlBu, RdYlGn
       ]

       set color lput 120 color                                 ;; add transparency to houses, current 120 is the best value for display

       set size 1                                               ;; make the house size to be 1

       set updateMortgage 1                                     ;; ask all houses need to have mortgage
  ]

end


;; creat certain % of all houses number of people, create their income, identify empty and rental houses group, and empty and purched houses group;
;; get one house from the purchased group first, if not available then from rental group;
;; a person will choose to live in the purchsed house, if can't, then live in rented house;
;; set up timeInHouse to be a random number within `mobility` and set is-occupied to be 1 ;
;; calc investmentCapital for the person as rentor or owner of the house;
;; paint the person color according to its income
to setup-people

  set-default-shape people "person"          ;; give all people a person-shape as default shape

  ;; [ check people number ] a proportion of houses to be people number
  let num-people (count houses * percent-occupied / 100)  ;; get the number of houses are occupied

  create-people num-people                   ;; create equal number of people to occupy the houses, and for each person
    [
                                             ;; [ check people income ]  create an random income between min to max income
      set income (random (max-income - min-income) + min-income)

      set myHouses []                        ;; every person has property myHouses, set it as empty list

      ;; [ check empty houses ]
      let housingList houses  with           ;; get all empty houses , into `housingList` agentset
          [
            count people-here = 0            ;; the land where the house is at has no people
          ]

    let tmpHouse 0                           ;; create a local house variable (tmpHouse is never a list, so we don't initialize it as [] )

                                             ;; [ check which empty houses the person can rent ]

      let myRentalList housingList with [    ;; get all houses not-occupied or empty,
          is-rental = 1 and                  ;; for-rental and
          rent < [income] of myself]         ;; the person's income > rent, can afford rent, --> under `myRentalList

                                             ;; [ check which empty houses the person can buy ]

      let myPurchaseList housingList with [  ;; get all houses not-occupied,
          is-rental = 0 and                  ;; not-rental and
          mortgageCost < [income] of myself] ;; the person's income > mortgageCost, can afford mortgage   --> under `myPurchaseList`

                                             ;; [ check - the person will prioritize buying then renting the house ]

      ifelse (count myPurchaseList > 0)      ;; if the houses the person can buy do exist
      [
        set tmpHouse one-of myPurchaseList   ;; get one of the houses under variable `tmpHouse`

      ]
      [
        if (count myRentalList > 0)          ;; otherwise, if the houses the person can rent do exist
        [
           set tmpHouse one-of myRentalList  ;; get one of the houses under variable `tmpHouse`

        ]
      ]


     move-to tmpHouse                        ;; move the person to where the targed house (to rent or to buy-own)

     set size 1                              ;; make person size be 1


     set timeInHouse random mobility         ;; randomize how long has the person stayed in the house, it may be any tick from 0 to 84 ticks

     set myHouses  lput tmpHouse myHouses    ;; put the house (to buy or to rent) at the last of the house list

                                             ;; [ check house occupied ] when people move in to rent or own, it is occupied

     ask item 0 myHouses                     ;; ask the first item of myHouses list
     [
       set is-occupied 1                     ;; make this house occupied, 1 as occupied, 0 as not
     ]

    let houseType [is-rental] of tmpHouse    ;; get the house rental-status, this is pre-determined when buiding the houses

    ifelse houseType = 1                     ;; if the house is rented

    [
      set investmentCapital (income - [rent] of tmpHouse)          ;; investmentCapital of the person is remaining of ( income - rent )
    ]
    [
      set investmentCapital (income - [mortgageCost] of tmpHouse)  ;; if the house is purchased, investmentCapital of the person is remaining of ( income - mortgageCost )
    ]


    ;; set color rgb 0 (100 + (155 * (income - min-income ) / (max-income - min-income))) 0
    ;; set color green            ;; these are three ways of coloring by values, but not as good as the code done in House2009
    ;; set color scale-color yellow income min-income max-income

    ;; [ check color people by income ]
    set color palette:scale-scheme "Divergent" "Spectral" 4  income  min-income  max-income  ;; Spectral , Divergent
                                                                   ;; divide people into 4 colors according to their income range
                                                                   ;; income color : red=smallest, yellow = small, green = medium, blue = large

    ]
end

to setup-banks

  set-default-shape banks "box"           ;; banks default to be box shape

  create-banks num-banks                  ;; create num-banks of banks
    [
      set color yellow                    ;; all banks are yellow

      move-to one-of patches with         ;; build banks on empty lands (randomly chosen)
        [count (turtles-here) = 0]

        set size 2                        ;; banks are big, twice size of house
    ]
end


to compute-bank-balances

  ask banks                                                           ;; ask each bank
  [
  let delta 0                                                         ;; local var delta 0

  ask mortgages with [which-bank = myself]                            ;; ask all and each mortgages whose bank is this bank
    [
     if [missedPaymentCount] of which-house > 0                       ;; if the mortgage's house missPaymentCount > 0
     [
     set delta (delta + (([price] of which-house) - purchasePrice))   ;; update delta by adding all the houses' (price - mortgage's purchasePrice) onto delta
     ]
    ]

  set incomeFromHouses delta                                          ;; delta is incomeFromHouses

  ifelse (delta < 0)                                                  ;; if bank income from the houses are negative, color red otherwise yellow
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
24
1060
544
-1
-1
15.5
1
15
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
85
72
setup
setup
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
92
38
147
76
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
153
39
208
77
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
20.0
1
1
%
HORIZONTAL

SLIDER
3
160
233
193
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
44.0
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
75.0
1
0
Number

INPUTBOX
1032
653
1187
713
max-price
150.0
1
0
Number

INPUTBOX
1137
653
1224
713
max-income
100.0
1
0
Number

INPUTBOX
928
725
1023
785
num-banks
20.0
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
-5
561
245
681
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
10.0
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
84.0
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

PLOT
1099
19
1259
462
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
252
572
518
692
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

CHOOSER
8
79
100
124
exp-options
exp-options
"base line"
0

CHOOSER
118
79
210
124
land-color
land-color
"black" "gray"
0

TEXTBOX
109
129
259
147
gray is better for viewing houses
8
0.0
1

TEXTBOX
632
10
1012
30
income color : red=smallest, yellow = small, green = medium, blue = large
8
0.0
1

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
NetLogo 6.0.4
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
