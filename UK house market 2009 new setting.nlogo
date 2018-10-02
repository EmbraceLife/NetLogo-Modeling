;extensions [profiler]
extensions [palette]
;;;
;;; PwC Housing Market model

;;; Updated and heavily modified and commented by 深度碎片 EmbraceLife
;;; this updated model and notes can be downloaded from https://github.com/EmbraceLife/NetLogo-Modeling
;;; video tutorials on updating and understanding this model are available below
;;; Chinese version see Bilibili: https://www.bilibili.com/video/av31860025/
;;; English version see Youtube: https://www.youtube.com/playlist?list=PLx08F1efFq_XPiMl74IHpppb8NGqITLn2

;;; originally written by Nigel Gilbert, n.gilbert@surrey.ac.uk
;;; the original model can be downloaded from http://cress.soc.surrey.ac.uk/housingmarket/ukhm.html

;;;
;;; Disclaimer
;;; This model has been prepared for general guidance on matters of interest only, and
;;; does not constitute professional advice.  The results are purely illustrative. You
;;; should not act upon any results from this model without obtaining specific professional
;;; advice.  No representation or warranty (express or implied) is given as to the accuracy
;;; or completeness of the model, and, to the extent permitted by law, PricewaterhouseCoopers,
;;; its members, employees and agents accept no liability, and disclaim all responsibility,
;;; for the consequences of you or anyone else acting, or refraining to act, in reliance on
;;; the model or for any decision based on it.
;;;
;;; This Housing Market model was developed by Nigel Gilbert with the assistance of John Hawksworth
;;;   and Paul Sweeney of PricewaterhouseCoopers and is licensed under a
;;;  Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License:
;;;  <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a><br /><span xmlns:dct="http://purl.org/dc/terms/" property="dct:title">Housing Market model</span> by <a xmlns:cc="http://creativecommons.org/ns#" href="http://cress.soc.surrey.ac.uk/housingmarket/ukhm.html" property="cc:attributionName" rel="cc:attributionURL">Nigel Gilbert</a> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>.
;;;
;;; To refer to this model in academic literature, cite:
;;; Gilbert, N, Hawksworth, J C, and Sweeney, P (2008) 'An Agent-based Model of the UK
;;;   Housing Market'.  University of Surrey http://cress.soc.surrey.ac.uk/housingmarket/ukhm.html
;;;
;;;  version 0    NG 18 October 2007
;;;  version 0.1  NG 09 November 2007
;;;  version 0.2  NG 17 November 2007
;;;  version 0.3  NG 23 November 2007 (bug: new entrants with zero mortgage)
;;;  version 0.4  NG 08 December 2007 (bug: movers not recorded as being in new house;
;;;                                    house prices reduced after no sale; purchasers
;;;                                    only have upper bound limiting offer;
;;;                                    entrants exit after a period if they can't find
;;;                                    a house; realtors add a percentage on to the
;;;                                    average price of local houses in forming their
;;;                                    valuation
;;;  version 0.5  NG 02 January 2008  New processes for realtor valuations and for
;;;                                    making offers
;;;  version 0.6  NG 26 January 2008  Added affordability, interest rate, house
;;;                                    construction, sliders and code
;;;  version 0.61 NG 11 February 2008 Added demolish proc to allow houses to die
;;;  version 0.72 NG 24 March 2008    Redid house valuation to allow for quality
;;;  version 0.8  JH, NG 4 April 2008 Adjusted initial parameters for more realistic
;;;                                    behaviour
;;;               NG 5  April 2008    Added gamma distribution for income, and income
;;;                                    plot
;;;  version 0.9  NG 17 April 2008    Added gini coefficient plot, changed display icons
;;;  version 0.91 NG 18 April 2008    Added mortgage interest/income plot
;;;  version 9.2  NG 19 April 2008    Added time on market plot, v. cheap houses get demolished
;;;  version 10.2 NG 26 May 2008      Added gains from investment, re-did paint houses to
;;;                                    use quantiles,
;;;                                    re-did clustering, made sure realtors did not
;;;                                    over-value
;;;  version 10.4 NG 22 Jun 2008      Added fake realtor records at setup.  Added correct
;;;                                    mortgage interest calculations,
;;;                                    inflation, slider for ticks per year
;;;  version 1.1  NG 22 Jun 2008      Up and down shocks now defined in terms of
;;;                                    Affordability, rather than hardwired numbers
;;;                                    adjusted initial valuations to value houses for
;;;                                    sale at start better
;;;  version 1.2   NG 17 Jul 2008     Dealt with -ve equity, repayments > income, and
;;;                                    further corrections to handling of mortgages.
;;;                                    General tidy up.  This is the version used for the
;;;                                    ESSA paper
;;;  version 1.3  NG 5 Sept 2008       1st time buyers get fixed capital
;;;  version 1.4  NG 6 Sept 2008       Added initial savings slider and disclaimer
;;;  version 1.5  NG 20 Jun 2011       Upgraded to work with NetLogo 1.4.3
;;;  version 1.6  NG 21 Dec 2013       Upgraded to NetLogo 5.0.4 and open sourced under a Creative Commons licence
;;;  version 1.61 NG 24 Jan 2013       Corrected bug introduced in upgrading to NL 5.0.4

;;;  version 1.7 深度碎片 2 Oct 2018    corrected bug introduced in upgrading to NL 6.0.4 with many tiny modifications and heavily commented.

globals [
;  scenario            ; to illustrate various step changes
  ;; these could become sliders
  initialVacancyRate  ; proportion of empty houses at start
  nRealtors           ; number of realtors
  min-price-fraction  ; if a house price falls below this fraction of the median price, it is demolished

  ; globally accessible variables (mainly here as globals so that they can be plotted)
  moves               ; number of households moving in this step
  interestPerTick     ; interest rate, after cyclical variation has been applied
  nUpshocked          ; number of owners putting their house for sale because their income has risen
  nDownshocked        ; number of owners putting their house for sale because their income has dropped
  nDemolished         ; number of houses demolished in this step
  medianPriceOfHousesForSale ; guess!
  nDiscouraged        ;; number of owners who discouraged by homeless and leave the city
  nExit               ;; number of owners who naturally leave the city or cease to exist
  nEntry              ;; number of owners who naturally enter or born into the city
  nForceOut           ;; number of owners whose repayment is greater than income and force to leave
  nOriginalOwners     ;; original number of owners at beginning
  nOwnersOffered      ;; number of owners who made an offer on a house (have enough money and have target to buy)
  meanIncomeForceOut  ;; cal the mean income of all owners who are forced out due to low income to repay mortgage
]

breed [houses house ]      ; a house, may be occupied and may be for sale
breed [owners owner ]      ; a household, may be living in a house, or may be seeking one
breed [realtors realtor ]  ; an estate agent
breed [records record ]    ; a record of a sale, kept by realtors

houses-own [
  my-owner            ; the owner who lives in this house
  local-realtors      ; the local realtors
  quality             ; index of quality of this house relative to its neighbours
  for-sale?           ; whether this house is currently for sale
  sale-price          ; the price of this house (either now, or when last sold)
  date-for-sale       ; when the house was put on the market
  my-realtor          ; if for sale, which realtor is selling it
  offered-to          ; which owner has already made an offer for this house
  offer-date          ; date of the offer (in ticks)
  end-of-life         ; time step when this house will be demolished
  ]

owners-own [
  my-house            ; the house which this owner owns
  income              ; current income
  mortgage            ; value of mortgage - reduces as it is paid off
  capital             ; capital that I have accumulated from selling my house
  repayment           ; my mortgage repayment amount, at each tick
  date-of-purchase    ; when my-house was bought
  made-offer-on       ; house that this owner wants to buy
  homeless            ; count of the number of periods that this owner has been
                      ;  without a house
  ]

realtors-own [
  my-houses           ; the houses in my territory
  sales               ; the last few house sales that I have made
  average-price       ; the average price of a house in my territory
  ]

records-own [         ; object holding a realtor's record of a transaction
  the-house           ; the house that was sold
  selling-price       ; the selling price
  date                ; the date of the transaction (in ticks)
  ]


to setup

  clear-all
  reset-ticks

;; we can experiment on one of five scenarios (analysis)
;; the choise is given in go procedure
;     if scenario = "ltv"  [ set MaxLoanToValue 60 ]
;     if scenario = "ratefall" [ set InterestRate 3 ]
;     if scenario = "influx" [ set EntryRate 10 ]
;     if scenario = "poorentrants" [ set MeanIncome 24000 ]
;     if scenario = "clusters", continue for 400 steps



;; initialise globals (in code, but there are globals in interface to be initialized as well )
  set initialVacancyRate 0.05
  set nRealtors 6  ;; original is 6, I shrink the size of agents (all kinds)
  set maxHomelessPeriod 5
  set interestPerTick InterestRate / ( TicksPerYear * 100 ) ;; meaning clarified in note
  set min-price-fraction 0.1

if scenario = "base-line" [
    set Inflation 0   ;; inflation rate 0 or 2
    set InterestRate 7  ;; 7 as 7% per year
    set TicksPerYear 4  ;; 4 ticks = a year
    set CycleStrength 0  ;; how much variation (0) is introduced to interest rate
    set Affordability  25  ;; 25% of income can be used to pay for mortgage
    set Savings 50   ;; 50% of income will be saved
    set ExitRate 2   ;; 2% of owners will exit city due to death or relocation of job each tick
    set EntryRate 5  ;; 5% of owners are new comers enter the city each tick
    set MeanIncome 30000  ;; mean income of whole population is 30000, used to calc each person's income using a gamma distribution
    set Shocked 20  ;; 20% of whole population will get an income shock (either up or down)
    set MaxHomelessPeriod 5  ;; maximum duration of homeless any one can stand before exit the city
    set BuyerSearchLength  10  ;; any buyer will only have patience to shop around maximum 10 houses
    set RealtorTerritory  8  ;; realtor's territory is a circle with radius equal to 8 units
    set Locality 3  ;;  local neighbors to a house is all the houses within 3 units distance to it
    set RealtorMemory 10  ;; any record can only live for 10 ticks
    set PriceDropRate  3  ;; if not sold at current tick, then drop sale-price by 3%
    set RealtorOptimism 3   ;; when doing a valuation for a house, raise valuation by 3% due to realtor's optimism
    set Density 70  ;; 70% of land are filled with houses
    set HouseMeanLifetime 100  ;; the end of life of a house is determined by a exponential distribution using the mean lifetime of all houses (100 years)
    set MaxLoanToValue 100  ;; maximum mortgage / house sale-price = 100% = 1
    set StampDuty? false  ;; do not consider StampDuty
    set MortgageDuration 25   ;; mortgage taks 25 years to repay
    set HouseConstructionRate 0.33  ;; each tick build new houses equal to 0.33% of current total houses
    set Income-shock 20  ;; income shock is to rise or fall by 20%
    set InitialGeography "Random"  ;; houses are located randomly, not by gradient nor cluster
    set price-difference 5000  ;; in cluster mode, consider houses whose price is more than 5000 differ from their neighbor houses, belong to different clusters
    set scenario "base-line" ;; automatically set all parameters to base line values
    set initialVacancyRate 0.05  ;; at the very beginning there are 5% of houses are empty
    set nRealtors 6   ;; there are 6 realtors in the city
    set min-price-fraction 0.1  ;; when the sale-price of a house drop to 10% of median price of all houses, make this house demolished.
    set interestPerTick InterestRate / ( TicksPerYear * 100 ) ;; convert interest rate per year to interest rate per tick
    set house-alpha 251 ;; no transparency
    set debug-setup "none"
    set debug-go "none"
    set exp-options "none"
]


;  no-display  ;; to make setup run faster, avoid display in process (given continous mode rather than tick mode)


;; 1. patches  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; make the world or land light gray from color swatches
  ask patches [ set pcolor gray + 3 ]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if debug? or debug-setup = "1 patches" [
  inspect patch 1 1
  user-message (word "1 patches : loop each patch, paint it muddy green. ")
  stop-inspecting patch 1 1
  ]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; 2 realtors  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; create and distribute the realtors (estate agents)

  set-default-shape realtors "flag"  ;;
  let direction random 360
  create-realtors nRealtors [  ;; create one at a time, totally nRealtors
    set color yellow
    ; distribute realtors in a rough circle
    set heading direction
    jump (max-pxcor - min-pxcor) / 4  ;; jump outward by 1/4 of length of the world
    set direction direction + 120 + random 30 ; prepare direction of jump for the next realtor
    set size 1  ;; original 3, here only 1 is visually good

    ; draw a circle to indicate a realtor's territory
    draw-circle RealtorTerritory   ;; RealtorTerritory is slider global variable

    ]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  if debug? or debug-setup = "2 realtors" [
;    inspect min-one-of realtors [who]
;    user-message (word "2 realtors : build realtors with flags, and draw circles as territory ")
;    stop-inspecting min-one-of realtors [who]
;  ]

  if exp-options = "realtor" [

     ask realtor 0 [
      inspect self
      type "this realtor is just created. " print ""
      user-message (word "")
    ]
  ]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; 3 houses;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; create and distribute the houses

  repeat (count patches * Density / 100) [ build-house ]
  ;; Density=70% is a slider global variable for houses, 70 houses on 100 patches, use this ratio to create enough houses for this world

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if debug? or debug-setup = "3 houses" [
    inspect max-one-of houses [who]
    user-message (word "3 houses : build a number of houses. Check which properties are initialized. " )
    stop-inspecting max-one-of houses [who]
  ]




  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; 4 owners: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; create the owners, one per house

  set-default-shape owners "dot"  ;; all owners are dots

  let occupied-houses n-of ((1 - initialVacancyRate) * count houses) houses  ;; randomly take (1 - initialVacancyRate) proportion of houses to be `occupied-houses`

  ask occupied-houses [  ;; define each home-owner's properties

    set for-sale? false  ;; since owners living inside, it should not for-sale now


    hatch-owners 1 [  ;; create an owner inside this house

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;      if debug? or debug-setup = "4 owners" [
;
;        inspect self
;        inspect one-of houses-here ;; here refers to patch underneath
;
;        user-message ( word " 4 owners : it is a bare owner " )
;      ]
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      set color red  ;; make owner red

      set size 0.7   ;; owner easy to see but not too big

      set my-house myself  ;; owner claims its house

      ask my-house [set my-owner myself ] ;; ask the house to claim its owner

      assign-income ;; create income and capital for owner

      if InitialGeography = "Gradient" [ set income income * ( xcor + ycor + 50) / 50 ]  ;; income increase from bottom-left to top-right

      set mortgage income * Affordability / ( interestPerTick * ticksPerYear * 100 ) ;; create mortgage

      let deposit mortgage * ( 100 /  MaxLoanToValue - 1 )  ;; create deposit

      ask my-house [ set sale-price [mortgage] of myself + [deposit] of myself ] ;; create sale-price = mortgage + deposit for the house

      set repayment mortgage * interestPerTick /
                 (1 - ( 1 + interestPerTick ) ^ ( - MortgageDuration * TicksPerYear ))



      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;      if debug? or debug-setup = "4 owners" [
;
;          user-message (word "4 owners : build an owner, initialize properties to owner and its house. " )
;
;          stop-inspecting self
;          stop-inspecting one-of houses-here
;        ]

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ]

    if exp-options = "house" and who = 0 [
       type " the house is made occupied by created an owner to it : check for-sale, my-owner" print ""
       user-message (word "" )
      ]

  ]

  set nOriginalOwners count owners
  paint-houses  ;; since houses got prices, let's paint houses



;; 5 empty  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; For vacant houses, without owners, those houses have no sale-prices, my-owner properties


   let ln-min-price precision ln [sale-price] of min-one-of houses with [ sale-price != 0 ] [sale-price] 1   ;; copy ln-min-price from paint-houses
   let ln-max-price precision ln [sale-price] of max-one-of houses with [  sale-price != 0 ] [sale-price] 1

   let median-price median [ sale-price ] of houses with [ sale-price > 0 ] ;; median sale-prices of all houses with owners

   ask houses with [ sale-price = 0 ] [  ;; loop each empty house

    if debug? or debug-setup = "5 empty" [

      inspect self ;; check bare empty house
      user-message (word "5 empty : check a bare empty house, to initialize my-owner, sale-price, and color it up " )
    ]

     set my-owner nobody  ;; my-owner from 0 to nobody

     let local-houses houses with [distance myself < Locality and sale-price > 0]
     ;; find all local houses of the empty house = locality distance and has owner with sale-price

     ifelse any? local-houses ;; if there exist local houses,
       [ set sale-price  median [ sale-price ] of local-houses ]  ;; use local houses median price as the empty house sale-price
       [ set sale-price  median-price ]  ;; otherwise, use all occupied houses median price for the empty house sale-price

     set color palette:scale-scheme "Divergent" "Spectral" 5 (ln sale-price) ln-min-price ln-max-price  ;; borrow it from paint-houses to color the empty house

    if debug? or debug-setup = "5 empty" [

      user-message (word "5 empty : No more a bare house, check my-owner, sale-price, and new color. " )
      stop-inspecting self
    ]
 ]



   if InitialGeography = "Clustered" [ cluster ]   ;; move houses to the neighbors with similar prices


;; 7 quality ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   set medianPriceOfHousesForSale median [sale-price] of houses  ;; get median price for all houses

   ask houses [

    set quality sale-price / medianPriceOfHousesForSale  ;; quality is sale-price/median-price

    if quality > 3 [set quality 3] if quality < 0.3 [set quality 0.3]  ;; quality is between 0.3 to 3


;    set color scale-color magenta quality 0 5  ;; quality by magenta scale

  ]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if debug? or debug-setup = "7 quality" [

    inspect max-one-of houses [ who ]
    user-message (word "7 quality: initialize quality of house, based on sale-price " )
    stop-inspecting max-one-of houses [ who ]
  ]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;; 9 realtors ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; initialize sales, my-houses, average-price

   ask realtors [
     set sales [] ;; take sales as empty list
     set my-houses houses with [member? myself local-realtors ]  ;; take all houses having the realtor as one of their local-realtors to be my-houses
     set average-price median [ sale-price ] of my-houses  ;; take median price of my-houses to be average-price
     ]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if debug? or debug-setup = "9 realtors: my-houses, avg-price" [
    inspect max-one-of realtors [ who ]
    user-message (word "9 realtors: initialize sales, my-houses, average-price for realtors ")
    stop-inspecting max-one-of realtors [ who ]
  ]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; 10 records;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; create records for each and every house
;; at the start, every house is assumed to be sold previously and has a record
;; the house's sale-price is the record's selling-price,
;; my-realtor is set randomly at the start, and this realtor will store the record into its sales list

  ask houses [ ;; loop each house



     let the-record nobody ;; `the-record` is nobody

     hatch-records 1 [  ;; hatch a record from a house

      if debug? or debug-setup = "10 records" [
         inspect myself ;; inspect the current house
         inspect self ;; inspect the current record
         user-message (word "10 records :  initialize the-house, selling-price for current record; initialize my-realtor for current house; update sales for my-realtor. ")
      ]
       hide-turtle  ;; hide the current record

       set the-house myself   ;; take the current house to be the-house of the current record

       set selling-price [ sale-price ] of myself  ;; take the sale-price of the house to be selling-price of the current record

       set the-record self                           ;; use the-record to carry the current record outside the hatch function into the house context
       ]

     set my-realtor one-of local-realtors  ;; randomly take one of the local-realtors to be my-realtor of the current house

     ask my-realtor [ file-record the-record ]  ;; ask my-realtor to save the current record (the-record) into sales of my-realtor

    if debug? or debug-setup = "10 records" [

      inspect my-realtor
      user-message (word "10 records :  initialize the-house, selling-price for current record; initialize my-realtor for current house; update sales for my-realtor. ")
      stop-inspecting self
      stop-inspecting the-record
      stop-inspecting my-realtor
    ]
  ]

   ;; to experiment for verification
   experiments

   paint-houses

   display

   do-plots

   reset-ticks

end

;; create random income and capital for an owner  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to assign-income

;; an owner's income is a random number from a particular gamma distribution
;; an owner's capital is a proportion of income

;; income distribution formula is based on the following paper
;; parameters taken from http://www2.physics.umd.edu/~yakovenk/papers/PhysicaA-370-54-2006.pdf


  let alpha 1.3
  let lambda 1 / 20000
  set income 0

  ; avoid impossibly low incomes (i.e. less than half the desired mean income)
  while [ income < MeanIncome / 2 ] [  ;; as long as income is less than half of median income

    set income (MeanIncome * lambda / alpha ) * (random-gamma alpha lambda) *
                      (1 + (Inflation / (TicksPerYear * 100)) ) ^ ticks  ;; redefine income value with this equation (check the paper for details )
    ]
  ; give them a proportion of a year's income as their savings
  set capital income * Savings / 100  ;; save up money or captial for buying houses every year

end

;; 2.5 build-a-house ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; created houses, make sure one patch one house, one house has at least one realtor, house for sale at first, set demolish-time
to build-house

  set-default-shape houses "my-house" ;; I changed the design of a house

  create-houses 1 [


;   hide-turtle  ;; original code, but I don't like house to be hidden
    set color 35 ;; set house to be brown

    ;; How to make transparent color ?
    set color lput house-alpha extract-rgb color

   ; for speed, dump the house anywhere, check if there is already a house there,
   ;  and if so, move to an empty spot
    move-to one-of patches
    if count houses-here > 1 [  ;; if more than 1 houses on the current patch ;;  houses-here == turtles-here, check document
;      user-message ( word "count houses-here > 1 is true, how many inside houses-here?  " count houses-here )

      let empty-sites patches with [ not any? houses-here ]  ;; ask every patch to see whether it already has a house on it or not, if not consider it an empty-site
;      user-message ( word "let empty-sites patches with [ not any? houses-here ], length empty-sites" count empty-sites) ;; debug for details

      if any? empty-sites [ move-to one-of empty-sites ]  ;; if empty-sites exist, let current house move to any one of the empty-site

      ]

    ; assign to a realtor or realtors if in their territory
    set local-realtors realtors with [ distance myself < RealtorTerritory ]  ;; if the realtor to the house distance < radius, make the realtor(s) for the house

    ; if no realtor assigned, then choose nearest
    if not any? local-realtors [ set local-realtors turtle-set min-one-of realtors [ distance myself ] ]  ;; turtle-set to check

    put-on-market  ; initially empty houses are for sale

    ; note how long this house will last before it falls down and is demolished
    set end-of-life ticks + int random-exponential ( HouseMeanLifetime * TicksPerYear )

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    if debug? or debug-setup = "2.5 build-a-house" [
       inspect self
       user-message (
        word "2.5 build-a-house : create a single house, paint it brown, make it transparent, move it a random patch without house, find local-realtors, "
        word "or just a nearest realtor, put on market for sale, calc end-of-life with random-exponential" "."
       )
       stop-inspecting self
    ]
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ]
end

to put-on-market        ;; house procedure
;; show that this house is for sale
    set for-sale? true
    set date-for-sale ticks
end

to draw-circle [radius]    ;; the current realtor turtle will create a new turtle to draw a circle as territory
;; draw the circumference of a circle at the given radius
  hatch 1 [  ;; based on current turtle, let's create/hatch a new turtle which inherit its parent's properties

    set pen-size 1 set color yellow set heading -90 fd radius  ;; set up pen size, color and radius for drawing a circle
    set heading 0  ;; set the heading to be tanget line direction
    pen-down
    while [heading < 359 ] [ rt 1 fd (radius * sin 1)  ]  ;; drawing a circle, see the debug proof below
;    user-message (word "finished drawing circle ? ") ;; yes, this is debugging

    die  ;; end the drawing turtle
   ]
end


;; 11 paint-log-price ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; scale-paint houses according to log of sale-price

to paint-houses

  let min-price precision [sale-price] of min-one-of houses with [ sale-price != 0 ] [sale-price] 1
  let ln-min-price precision ln [sale-price] of min-one-of houses with [ sale-price != 0 ] [sale-price] 1
  let max-price precision [sale-price] of max-one-of houses with [  sale-price != 0 ] [sale-price] 1
  let ln-max-price precision ln [sale-price] of max-one-of houses with [  sale-price != 0 ] [sale-price] 1

  ask houses with [ sale-price != 0 ] [  ;; maybe set empty house initial 0 price to "0" ?

    if debug? or debug-setup = "11 paint-log-price" [
      follow-me
      user-message (word " 11 paint-log-price : loop each house , paint each house with divergent colors based on log sale-prices " )
    ]

    set color palette:scale-scheme "Divergent" "Spectral" 5 (ln sale-price) ln-min-price ln-max-price

    ; scale-scheme "Divergent" "RdYlBu" 10 ; the number 10 control how many different colors in between, 5 may be the best
    ; good color options:  "Spectral" "RdYlBu" "RdYlGn"
    ;; ok color options : PiYG PRGn PuOr RdBu RdGy
    ;; set color scale-color red ln sale-price ln-min-price ln-max-price



    set color lput house-alpha color  ;; add transparency to color

    if debug? or debug-setup = "11 paint-log-price" [

      user-message (word " 11 paint-log-price : loop each house , paint each house with divergent colors based on log sale-prices " )
    ]

  ]



end


;; 6 cluster ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to cluster
;; cluster houses together based on price similarity

  repeat 3 [  ;;  cluster all all houses three times

    paint-houses   ;; scale-paint houses based on log sale-price

    let houses-to-move sort-by [ [ house1 house2 ] ->  price-diff house1 > price-diff house2 ] houses  ;; new-version
    ;; reorder every house based on price-difference to its neighbor houses, largest first, smallest last


    foreach houses-to-move [  ;; loop each house

      x -> if price-diff x >= price-difference [  ;; if current house price is way too different from its surroundign houses

        let vacant-plot one-of patches with [  ;; get one of many empty patches, where

                                   not any? houses-here and  ;; there is no house built

                                   abs (local-price - [ sale-price ] of x ) < 1000 ]  ;; where the surrounding house prices is similar to the current house

        if vacant-plot != nobody [  ;; if those empty patches do exist

          ask x [  ;; ask this current house

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            if debug? or debug-setup = "6 cluster" [

              pd set pen-size 2  ;; put pen down to draw a track

              if is-owner? my-owner [

                ask my-owner [ follow-me ]  ;; watch the owner ( can't use watch-me here)

              ]
              user-message (word "6 cluster : the house move with a track line, the owner is watched. " )
            ]
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

            move-to vacant-plot  ;; to move to one of the empty patch

            if is-owner? my-owner [  ;; whether it got an owner, if so

              ask my-owner [ move-to myself ] ;; ask the owner move to where the house is
            ]

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            if debug? or debug-setup = "6 cluster" [

               user-message (word "6 cluster : the house move with a track line, the owner is watched. " )

               pen-up ;; pull pen up
            ]
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

           ]

          ]
        ]
      ]


  ]

end

;; find out median price for local houses ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report local-price

  let local-houses houses-on neighbors  ;; based on the current patch, looking for its eight neighbor patches, put all the houses on those patches under `local-houses`

  ifelse any? local-houses  ;; if `loca-houses` is not empty

    [ report median [sale-price] of local-houses ]  ;; report median price of all neighbor houses' sale-prices to be `local-price`

    [ report 0 ] ;; if no neighbor houses, report 0 to be `local-price`

end

;; find out the price difference between a house and its neighbors ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report price-diff [ a-house ]

  report abs ([sale-price] of a-house - [local-price] of a-house) ;; Note the use [ local-price ] of a-house

end



  ;; experiment for verification ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to experiments
  if exp-options = "track-owner-numbers" [
    type "nOriginalOwners: " type nOriginalOwners type " owner without house: " type count owners with [not is-house? my-house ]
    type " nOwnersOffered: " type nOwnersOffered  ;; each tick how many owners can afford a targeted house to buy
    type " owners now: " type (count owners) type " exit: " type nExit
    type " entry: " type nEntry type " nDiscouraged: " type nDiscouraged type " nForceOut: " type nForceOut  print ""
  ]

  if exp-options = "track-houses-sales-numbers" [
     let sum-sales 0 ask realtors [ set sum-sales sum-sales + length sales] show sum-sales
     let sum-houses 0 ask realtors [ set sum-houses sum-houses + count my-houses] show sum-houses
     type "total houses: " type count houses type ", total sales: " type sum-sales type ", total houses under 3 realtors (include duplicated) : " type sum-houses print ""
  ]

end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go

  set nDiscouraged 0
  set nExit 0
  set nEntry 0
  set nForceOut 0
  set nOwnersOffered 0
  set meanIncomeForceOut 0 ;; get mean income of owners who are forced out

   if debug? or debug-go = "s0 go-structure" [
     user-message (word "s0 go-structure : set simulation duration, half time bring in a scenario, one step per go, 3 conditions to stop simulation. Now let's run! ")

  ]

;; basic loop
   if ticks > 400 [

    print "Finished: 400 ticks reached "

    stop ]

   if ticks = 200 [
     if scenario = "ltv"  [ set MaxLoanToValue 60 ]
     if scenario = "raterise 3" [ set InterestRate 3 ]
     if scenario = "raterise 7" [ set InterestRate 7 ]
     if scenario = "raterise 10" [ set InterestRate 10 ]
     if scenario = "influx" [ set EntryRate 10 ]
     if scenario = "influx-rev" [ set EntryRate 5 ]
     if scenario = "poorentrants" [ set MeanIncome 24000 ]

     type "We are at middle of simulation duration, ticks = " type ticks type ", a shock event coming in := " type scenario  print ";"

     ]

  set nOwnersOffered 0
  step  ;; do one time step (a quarter of a year?)

  if not any? owners [ user-message(word "Finished: no remaining people" ) stop ] ;; stop if no owners or houses left
  if not any? houses [ user-message(word "Finished: no remaining houses" ) stop ]

  do-plots  ;; update the plots


  ;; experiment for verification
  experiments


  tick  ;; advance the clock


end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to step
;;  each time step...

  ;; count total number of owners ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  let n-owners count owners  ;; take a count of total owners at the moment

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if debug? or debug-go = "s1 count-owners" [ user-message (word "s1 count-owners : to start, count total number of all owners = " n-owners) ]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  ;; calc interest per tick ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; add an exogenous cyclical interest rate, if required: varies around mean of
  ; the rate set by slider with a fixed period of 10 years

  set interestPerTick InterestRate / ( TicksPerYear * 100 )

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if debug? or debug-go = "s2 interestPerTick" [ user-message ( word "s2 interestPerTick : from interest per year to interest per tick"  ) ]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  ;; add cyclical variation to interest ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if CycleStrength > 0 [
    set interestPerTick interestPerTick * (1 + (CycleStrength / 100 ) * sin ( 36 * ticks / TicksPerYear )) ]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if debug? or debug-go = "s3 interest-Cycle"
    [ user-message (word "s3 interest-Cycle : add cyclical influence to interestPerTick. see the figure. " ) ]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  ;; inflation drive up income ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; add inflation to salary, at inflation rate / TicksPerYear
  if Inflation > 0 [

    ask owners [

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      if debug? or debug-go = "s4 inflation-income" [
         inspect self
         user-message ( word "4 inflation-income : inflation will drive up income accordingly. " precision income 1)
      ]
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      set income income * (1 + Inflation / ( TicksPerYear * 100 )) ;; every tick, income stay the same or varied by inflation

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      if debug? or debug-go = "s4 inflation-income" [
         user-message ( word "s4 inflation-income : inflation will drive up income accordingly. " precision income 1)
         stop-inspecting self
      ]
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ]
  ]


  ;; get all the owners with houses ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  let owner-occupiers owners with [ is-house? my-house ]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if debug? or debug-go = "s5 owner-occupiers" [ user-message (
    word "s5 owner-occupiers : bring all owners with houses under variable `owner-occupiers`. the count = " count owner-occupiers ) ]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  ;; introduce income rise and fall shock to owners ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  let shocked-owners n-of (Shocked / 100 * count owner-occupiers ) owner-occupiers ;; gather Shocked% of `owner-occupiers` under `shocked-owners`

  let upshocked n-of (count shocked-owners / 2) shocked-owners ;; gather half of `shocked-owners` under `upshocked`

  set nUpShocked 0  ;; initialize the number of upshocked owners under `nUpShocked`

  ask upshocked [ set income income * (1 + income-shock / 100) ] ;; ask each `upshocked` to increase income by 20%

  let downshocked shocked-owners with [ not member? self upshocked ] ;; gather the non-upshocked as down shocked owners under `downshocked`

  set nDownShocked 0 ;; initialize the number of upshocked owners under `nUpShocked`

  ask downshocked [ set income income * (1 - income-shock / 100 ) ]  ;; ask each downshocked to drop income by 20%

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if debug? or debug-go = "s6 income-shock" [
    user-message (
      word "s6 income-shock : each tick, a Shocked% of home-owners got income shock = " Shocked
      word "; half income rise income-shock% the other drop income-shock% = " income-shock
    )
  ]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  ;; income-shock intrigers some owners to sell houses ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; after income shock, which type of owners will sell houses due to income rise, and which type of owners sell houses due to income drop
  ask owner-occupiers with [ not [for-sale?] of my-house ][ ;; ask all home-owners whose house is not for sale (in setup, all home-owners don't sell houses)

   let ratio repayment * TicksPerYear / income ;; put yearly-repayment / income  under `ratio`

   if  ratio < Affordability / 200 [  ;; if ratio < half of Affordability %, meaning yearly-repayment is easy and owner is rich

      ask my-house [ put-on-market ]  ;; ask owner's house to put on the market for sale

      set nUpShocked nUpShocked + 1   ;; add 1 to `nUpShocked`, meaning one more owner selling house due to income rise

    ]

   if ratio > Affordability / 50 [   ;; if ratio > 2 * Affordability % , meaning yearly-repayment is way to heavy for owners to bear, owner is poor

      ask my-house [ put-on-market ]  ;; ask owner's house to put on the market for sale

      set nDownShocked nDownShocked + 1  ;; add 1 to `nDownShocked`, meaning one more owner selling house due to income drop

    ]
   ]
     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   if debug? or debug-go = "s7 shock-sale" [
     user-message (
        word "s7 shock-sale : after income-shock, only owners whose repayment < half of affordability, will put house on sale due to income rise; "
        word " only owners whose repayment > twice of affordability,  will put house on sale due to income drop " "."
      )]
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



  ;; owners die or leave naturally ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; every tick, a proportion of owners put their houses on the market and leave town

  ask n-of (ExitRate * n-owners / 100) owners with [ is-house? my-house ] [  ;; ask randomly select (ExitRate% of all owners) number of home-owners to do ...

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    if debug? or debug-go = "s8 owners-gone" [
       inspect self
       inspect my-house
       user-message (
          word " s8 owners-gone : watch this owner to sell and leave. "
          word " it is one of = " round (ExitRate * n-owners / 100)
      )]
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ask my-house [

      put-on-market  ;; put itself on market
      set my-owner nobody

      ]

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    if debug? or debug-go = "s8 owners-gone" [ user-message (word " watch the changes " )
        stop-inspecting self
        stop-inspecting my-house
    ]
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    set nExit nExit + 1

    die

  ]



  ;; new comers ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; a fixed number of new comers enter the city

  repeat EntryRate * n-owners / 100 [
;  create-owners EntryRate * n-owners / 100 [  ;; create a fixed proportion of new owners
    create-owners 1 [

      set color gray  ;; gray
      set size 1 ;; to make new comers differ from other owners

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      if debug? or debug-go = "s9 new-comers" [

        inspect self  ;; inspect one of new comer
        follow-me  ;; watch it

        user-message (word "s9 new-comers : create a new comer and watch its properties " )
      ]
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      set size 0.7  ;; make them visible but not too big

      assign-income  ;; initialize income and capital

      hide-turtle  ;; new comers have no houses, so they are nowhere to be seen

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      if debug? or debug-go = "s9 new-comers" [
        user-message (word "s9 new-comers, now it is hidden. " )
        stop-inspecting self
      ]
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      set nEntry nEntry + 1
    ]
  ]


  ;; discouraged-leave ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; if an owner without home for too long, it will move out of city

  if MaxHomelessPeriod  > 0 [ ; meaning if this value is set

       ask owners with [ not is-house? my-house ] [  ;; ask each owner without a house

         set homeless homeless + 1  ;; count the owner's homeless duration

         if homeless > maxHomelessPeriod [ ;; if homeless duration is beyond limit, this owner will move out of the city (agent die)

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            if debug? or debug-go = "s10 discouraged-move-away" [
               inspect self
               user-message ( word " this owner's homeless duration is " homeless )
            ]
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

            set nDiscouraged nDiscouraged + 1
            die
          ]
     ]
  ]





  ;; income < repayment, house taken, and owner force leave ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  let total-drop-sale count owner-occupiers with [ [for-sale?] of my-house and repayment * TicksPerYear > income ]
  ;; get all home-owners whose houses are on-sale and whose yearly-repayment is larger than income, and count the number `total-drop-sale`


  let ForceOut owner-occupiers with [ [for-sale?] of my-house and ;; get all home-owners whose houses are on-sale and

                              repayment * TicksPerYear > income ]   ;; whose yearly-repayment is larger than income

  set nForceOut count ForceOut  ;; count the number of owners have forced out of city

;   meanIncomeForceOut  ;; get their mean income
  ask ForceOut [  ;; ask each of the forced out people
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    if debug? or debug-go = "s11 drop-sale" [
        user-message (word "s11 drop-sale : this owner's yearly repayment = " (repayment * 4 )
                      word ", the owner's income is only " income
                      word ", this owner can't repay mortgage, forced out" ". "
      )
    ]
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ask my-house [ set my-owner nobody ]  ;; ask its house to set owner to be nobody

    set meanIncomeForceOut meanIncomeForceOut + income  ;; to sum up all income of the owners who are forced out
    die  ;; ask the owner to die
    ]
    ifelse  nForceOut > 0 [ set meanIncomeForceOut meanIncomeForceOut / nForceOut ] [ set meanIncomeForceOut 0]  ;; take the mean
;    if meanIncomeForceOut > 0 [user-message( word " meanIncomeForceOut " meanIncomeForceOut ) ]


  ;; some new houses are built, and put up for sale ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  repeat count houses * HouseConstructionRate / 100 [  ;; build a fixed proportion of new houses

    if any? patches with [ not any? houses-here ]  [ ;; patches with [ not any? houses-here ] = patches where there are no houses on them
                                                     ;; any? patches with  = do these patches exist or not

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      if debug? or debug-go = "s12 new-houses" [

        user-message (word "s12 new-houses : as long as there is an empty land, build a house, until the number is met. " floor (count houses * HouseConstructionRate / 100)
      ) ]
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      build-house   ;; this function will automatically find an empty land to build a house on

    ]

  ]


  ;; update 0-quality houses to [0.3, 3] ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ask houses with [ quality = 0 ] [ ;; ask each house with quality = 0

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      if debug? or debug-go = "s13 remove-0-quality" [
         inspect self
      user-message (word "s13 remove-0-quality : see the quality changes. In total 0-quality houses number = " count houses with [ quality = 0 ] )]
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      let houses-around-here other houses in-radius Locality
      ;; put ( the other houses which are within the radius circle where the current house is the center ) under `houses-around-here`

      set quality ifelse-value any? houses-around-here ;; if `houses-around-here` exist, then return first value to `quality`

        [ mean [ quality ] of houses-around-here ]

        [ 1 ]                                          ;; if `houses-around-here` exist, then return second value to `quality`


      if quality > 3 [set quality 3]  ;; quality has upper limit to be 3

      if quality < 0.3 [set quality 0.3]  ;; quality has lower limit to be 0.3

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    if debug? or debug-go = "s13 remove-0-quality" [
      user-message (word "s13 remove-0-quality : see the quality changes. ")
      stop-inspecting self
    ]
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ]





  ;; value-houses ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; initially, house sale-price is added up by mortgage and deposit in setup
  ;; once a house put on sale, sale-price, my-realtor (house) , average-price (realtor), median price for all houses on sale, are to be updated.

  let houses-for-sale houses with [ for-sale? ] ;; find all the houses for sale

  if any? houses-for-sale [  ;; if these houses exist

    ask houses-for-sale with [ date-for-sale = ticks ] [  ;; ask each of those houses which are just on sale from now on

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      if debug? or debug-go = "s14 value-houses" [

        inspect self

        user-message (word "s14 value-houses : valuation current house, compare changes of house and realtor properties. ")]
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      set my-realtor max-one-of local-realtors [ valuation myself ]  ;; set the realtor gives the current house the highest valuation to be my-realtor

      set sale-price [ valuation myself ] of my-realtor ;; take the highest value valuation price as sale-price of the current house

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      if debug? or debug-go = "s14 value-houses" [

         user-message (word "s14 value-houses : sale-price, my-realtor are updated. ")

        stop-inspecting self ]
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ]


    ; update the average-price of each realtor
    ask realtors [ ;; ask each realtor

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      if debug? or debug-go = "s15 realtor-average-price" [

        inspect self

        user-message (word "s15 realtor-average-price : update realtor's average-price. " )]
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




      let my-houses-for-sale houses-for-sale with [ member? myself local-realtors ];; get all houses under this realtor

      if any? my-houses-for-sale [ set average-price median [ sale-price ] of my-houses-for-sale ]
      ;; if these houses exist, take their median price as the realtor's average-price for its all houses

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      if debug? or debug-go = "s15 realtor-average-price" [

        user-message (word "s15 realtor-average-price : average-price is updated. ")

        stop-inspecting self
      ]
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ]

    set medianPriceOfHousesForSale median [sale-price] of houses-for-sale  ;; update median price of all houses on sale
  ]

  paint-houses  ;; update colors after prices are updated


  ;; make an offer ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; owners without houses or whose houses are on-sale, can make offers to other houses on sale

  let buyers owners with [ not (is-house? my-house) or ([ for-sale? ] of my-house) ]  ;; put all owners who don't have a house or whose houses on sale under `buyers`

  ask owners with [ not (is-house? my-house) ] [ ;; ask each owner who has no house to make an offer on `houses-for-sale`
    make-offer houses-for-sale
    ]


  ask owners with [ (is-house? my-house) and ([ for-sale? ] of my-house) ] [ ; and now those who do have a house to sell get a chance to make an offer on `houses-for-sale`
    make-offer houses-for-sale
    ]

  set nOwnersOffered count owners with [is-house? made-offer-on ] ;; count the number of owners who has an affordable house to buy


  ;; move into new houses ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; if a deal is made, then households will move in and out of houses
   set moves 0  ;; the number of households moving in this step

   ask buyers with [ not is-house? my-house and is-house? made-offer-on ] [ ;; ask buyers who have no houses and made offer on a house

     if follow-chain self [  ;; self is buyer, and check whether the buy-sell chain is intact or not

       move-house  ;; if intact, deal is made, and households move out and into houses, count the number of moves
     ]
   ]


;  if debug? or debug-go = "34 follow-chain" [
;   user-message (word "34 follow-chain, step 22 : check whether the buy-sell houses mechanism is intact or not. "
;                 word "1. if buyer's `made-offer-on` is not house (meaning buyer buy nothing, no deal), report false; "
;                 word "2. given the buyer offered on a real house, then set `my-owner` of the house being offered on to be `seller`; "
;                 word "3. if the `seller` is not an `owner` (meaning the house is vacant, deal right away ), report true; "
;                 word "4. given `sell` is an owner, if the input `buyer` =  `seller`, then the flow is intact, This is confusing, but don't be. The following line solve the problem. "
;                 word "5. given the buyer is not the seller (no match), now let's focus on the seller, run follow-chain under seller context, meaning we are finding the owner of house which the seller made an offer on; "
;                 word "if the buyer and the seller of the house the older sell want to buy are the same owner, then both buyer and older seller match a deal." "so the flow is intact. "
;   )
;]

;  if debug? or debug-go = "35 move-house" [
;      user-message (word "35 move-house, step 23 : move me to the house I am buying, then move the seller to their new house etc. "
;                    word "1. under context of buyer or owner, save `made-offer-on` into `new-house`; "
;                    word "2. if the `new-house` is not house, meaning buyer is not buying, then stop moving; "
;                    word "3. assign `my-owner` of `new-house` into `seller`; "
;                    word "4. if seller is an owner, calc the profit made by selling the house: "
;                    word "assign (sale-price - mortgage) to `profit`, and set seller's mortgage to 0; "
;                    word "If sell made a profit, then add profit into seller's capital. "
;                    word "5. since deal is made, change new-house owner to the buyer; "
;                    word "6. calc the duty payable with the new house sale-price; "
;                    word "7. if the owner can't pay for the house in cash, s/he has to have a mortgage, "
;                    word "borrow as much as possible, given owner's income and value of house, choose the smaller value of two calc formula; "
;                    word "8. after paying rest with capital, the remaining still kept inside capital. "
;                    word "9. calc repayment to pay back mortgage; "
;                    word "10. or if the buyer is a cash buyer, capital pays all, mortgage, repayment both are 0; the remaining still kept in capital "
;                    word "11. if buyer's capital is not enough for downpayment, set the negative remaining to 0; but this no enuogh capital for down-payment should not happen, why here? "
;                    word "12. new entrants are now made visible, and move buyer to its new house, set buyer's homeless period to 0; "
;                    word "13. set buyer's `my-house` to be the `new-house`, record the current ticks when the house is bought as `date-of-purchase`; "
;                    word "14. ask each new-house to put off market and make `offered-to` as nobody; "
;                    word "15. under buyer's context, buyer is not making any offer now; create a new record under the buyer context; "
;                    word "16. make record invisible, record current ticks to be the `date` of record, assign the current `new-house` to be `the-house` of record; "
;                    word "17. assign the `sale-price` of new-house to be `selling-price` of record; ask the new-house realtor to save record into its sales list; "
;                    word "18. count 1 more moving household into `moves`; if sell as owner exist, then ask seller to move-house too" "."
;     )
;  ]




   ;; remove old record ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ; after certain period, all old records should be removed, realtors will remove all their sales
   ask records [ if date < (ticks - RealtorMemory) [ die ] ] ;; for each record, after RealtorMemory duration, it has to be removed

   ask realtors [ set sales remove nobody sales ] ;; ask realtors to remove dead records from the sales list


   ;; remove offers ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ; remove the offer information upon a house
   ask houses with [ is-owner? offered-to ] [  ;; for each of the houses which have owners/buyer to make offer on

     ask offered-to [ set made-offer-on nobody ] ;; ask each buyer to set property `made-offer-on` as nobody

     set offered-to nobody  ;; set the house's buyer property `offered-to` to be nobody

     set offer-date 0  ;; set house property `offer-date` to 0
     ]

  ;; demolish houses ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;demolish old houses or houses with below minimum price
   set nDemolished 0  ;; record the number of demolished houses at each tick

   if any? records [  ;; if there are records left

     let minimum-price min-price-fraction * medianPriceOfHousesForSale ;; set minimum-price to be 10% of all sold-houses median price

     ask houses with [ (ticks > end-of-life) or  ;; ask all houses, if its life is over its life limit or

                       (for-sale? and sale-price <  minimum-price )] ;; if the house is for sale and sale-price < minimum-price

         [ demolish ]  ;; let's demolish the house
    ]

;  if debug? or debug-go = "36 remove-records-offers-houses" [
;      user-message (word "36 remove-records-offers-houses, step 24 : after certain period, all old records should be removed, realtors will remove all their sales: "
;                    word "1. since the record is created, after RealtorMemory duration (update is needed now), ask all records to die; "
;                    word "2. ask realtors to remove dead records from the sales list. "
;                    word "Next, remove the offers to houses : 1. for each of the houses which have owners/buyer to make offer on, "
;                    word "ask each buyer to set property `made-offer-on` as nobody, set the house's buyer property `offered-to` to be nobody, "
;                    word "set house property `offer-date` to 0. Finally, demolish old houses or houses with below minimum price. "
;                    word "1. use this variable to record the number of houses demolished; if there are records left, set minimum-price to be 10% of all sold-houses median price; "
;                    word "2. ask all houses, if its life is over its life limit or if the house is for sale and sale-price < minimum-price, let's demolish the house" "."
;    )
;  ]



  ;; reduce or update sale-prices of unsold houses ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; reduce sale-price is a house is not sold in each tick
  ask houses with [ for-sale? ] [  ;; ask all houses which still are for sale

     set sale-price sale-price * (1 - PriceDropRate / 100 );; to reduce its sale-price by certain amount
     ]



  ;; update owners' mortgage and repayment in each tick  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ask owners with [ is-house? my-house and mortgage > 0 ] [  ;; ask all owners who do have houses and mortgage to pay

    set mortgage mortgage - ( repayment - interestPerTick * mortgage );; mortgage will be reduced due to repayment

    if mortgage <= 0 [  ;; if mortgage is fully repaid, then set both mortgage and repayment to 0

      set mortgage 0
      set repayment 0
      ]
    ]

;  if debug? or debug-go = "37 update-house-owner" [
;     user-message( word "37 update-house-owner, step 25 : update houses sale-price 1. ask all houses which still are for sale, "
;                   word "to reduce its sale-price by certain amount. Now, update owners' mortgage and repayment : "
;                   word "1. ask all owners who do have houses and mortgage to pay, mortgage will be reduced due to repayment; "
;                   word "2. if mortgage is fully repaid, then set both mortgage and repayment to 0" "."
;     )
;  ]


;  if debug? or debug-go = "38 demolish" [
;   user-message (word "38 demolish, step 26 : let demolish the house and everything associate it. "
;                 word "1. under the context of the house, check the household is owner or not, if it is owner, set my-house nobody, "
;                 word "set mortgage and repayment to 0, set the owner invisible, meaning the owner is homeless; "
;                 word "2. delete any record that mentions the house inside the sales of a realtor, set the land to be muddy green, "
;                 word " add 1 upon nDemolished, make the house die" "."
;   )
;]

end


;; valuation house price by realtor ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report valuation [ property ]    ;; realtor procedure


  let normalization 1  ;; create a local variable normalization

  let multiplier [ quality ] of property *          ;; create a multiplier for final finish of valuation price
                  (1 + RealtorOptimism / 100) * normalization  ;; component of multiplier include quality, optimism, normalization

;    let local-sales (turtle-set sales) with [ ( [distance property ] of the-house ) < Locality ]  ;; old-version
  let local-sales (turtle-set sales) with [ the-house != nobody and ( [distance property ] of the-house ) < Locality ]  ;; new-version
;; under realtor context, sales is a list of records, use `turtle-set` force list into an agentset to use with, each record has property of the-house
;; get all the sales (lists of records) whose houses are sold and those sold-houses are neighboring to the input house under `local-sales`

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if any? local-sales and ( debug? or debug-go = "s18 valuation 1" ) [
    ask property [ set size 2 ]
    ask local-sales [ ask the-house [ set pcolor pink ] ]
    user-message (word "s18 valuation 1 : identify neighboring and sold houses. Enlarge them. ")
  ]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  let old-price [sale-price] of property  ;; set the input house's sale-price as old price

  let new-price 0  ;; create a new price variable with 0 value

  ifelse any? local-sales  ;; if the local-sales exist

    [ set new-price median [ selling-price ] of local-sales ] ;; assign the median price of all record houses to new-price

    [ let local-houses houses with [ distance myself <= Locality  ];; if no local-sales exist, take neighboring houses around the current realtor under `local-houses`

      ifelse any? local-houses  ;; if local-houses exist

        [set new-price median [sale-price] of local-houses  ;; set the median price of all local-houses to be new-price


         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
         if debug? or debug-go = "s19 valuation 2"  [
             ask property [ set size 3 ]
             ask self [ set color red ]
             ask local-houses [ set pcolor pink ]
             user-message (word "s19 valuation 2 : identify neighboring houses to the realtor. Display them. ")
           ]
         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    ]

        [set new-price average-price ] ;; otherwise set average-price of the realtor to be new-price (is realtor's average-price updated every tick?)



  ]


  if old-price < 5000 [ report multiplier * new-price ]  ;; if current sale-price is too low, just accept multiplier * new-price  as valuation price

  let ratio new-price / old-price  ;; compare calc ratio between new-price and old-price

  let threshold 2  ;; a base line for ratio

  ifelse ratio > threshold  ;;

    [ set new-price threshold * old-price ] ;; if new-price is more than twice old-price,  make new-price twice of old-price. "

    [ if ratio < 1 / threshold [  set new-price old-price / threshold ] ]  ;;  if new-price is less than half of old-price, make new-price half of old-price.

  report  multiplier * new-price  ;; finally report multiplier * new-price" "."

end


;; make offer on houses on sale ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to make-offer [ houses-for-sale ]

  let new-mortgage income * Affordability / ( interestPerTick * ticksPerYear * 100 );; use current income, Affordability, interestPerTick to calc new-mortgage

  let budget new-mortgage - stamp-duty-land-tax new-mortgage  ;; actual budget for buying a house == new-mortgage - duty or tax we get back

  let deposit capital  ;; buyer use capital to pay for new deposit

  if is-house? my-house [ set deposit deposit + ([ sale-price ] of my-house - mortgage) ]
  ;; under the context of owners, if it has a house, update new deposit with new deposit + sale-price of current house - current mortgage

  let upperbound budget + deposit  ;; upperbound = the maximum amount afford to offer on a house = new mortgage - duty-back + new deposit

  if MaxLoanToValue < 100 [  ;; if mortgage is less than house value => (MaxLoanToValue/100 < 100/100 )

    set upperbound min ( list (budget + deposit ) ( deposit / ( 1 - MaxLoanToValue / 100 )))  ;; update upperbound with the less between two similar values

    ]


  if upperbound < 0 [  ;; if upperbound is less than 0, meaning the owner has negative equity (how it is possible?)

    ask my-house [ set for-sale? false ] ;; pull the house back from market, and stay in the house

    stop ;; this owner stop performing the rest action below
    ]

  let lowerbound upperbound * 0.7  ;; set lowerbound to be 70% of upperbound

  let current-house my-house  ;; get the current owner's my-house under `current-house`

  let interesting-houses houses-for-sale with [ ;; from all the houses on sale, get those

                            not is-owner? offered-to and ;; without offer

                            sale-price <= upperbound and ;; and sale-prices within upperbound

                            sale-price > lowerbound and  ;; and sale-prices greater than lowerbound

                            self != current-house ]  ;; and the house is not current house,            --->  into `interesting-houses`

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if debug? or debug-go = "s20 make-offer part1" [
    ask interesting-houses [ set size 2 ]
    user-message (word "s20 make-offer part1, identify the interesting houses buyers may make an offer. See the enlarged houses. " )
    ask interesting-houses [ set size 1 ]
  ]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  if count interesting-houses > BuyerSearchLength [  ;; if number of interesting-houses > BuyerSearchLength (number of houses buyers willing to see)

    set interesting-houses n-of BuyerSearchLength interesting-houses ;; then select randomly BuyerSearchLength number of interesting-houses
    ]

  if any? interesting-houses [  ;; if interesting-houses exist

    let property max-one-of interesting-houses [ sale-price ]  ;; find the house with the maximum sale-price of interesting-houses and assigned to `property` a local-var

      if is-house? property [  ;; if the `property` is a house

        ask property [  ;; ask this house

          set offered-to myself  ;; assign the current owner as `offered-to` under the context of `property`

          set offer-date ticks   ;; set `ticks` to be `offer-date` (house property)
        ]

        set made-offer-on property  ;; assign `property` (a house ) to owner's property `made-offer-on`

    ]

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    if debug? or debug-go = "s21 make-offer part2" [
      ask property [ follow-me ]

      user-message (word "s21 make-offer part2 : choose from interesting houses and make an offer on the most expensive house, and update its `offered-to` and `offer-date`." )
  ]
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

     ]



end


;; set three duty return thresholds ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to-report stamp-duty-land-tax [ cost ]
  ;; stamp duty land tax ('stamp duty') is 1% for sales over $150K, 3% over $250K, 4% over $500K,  (see http://www.hmrc.gov.uk/so/rates/index.htm )
  if StampDuty? [

    if cost > 500000 [ report 0.04 * cost ]

    if cost > 250000 [ report 0.02 * cost ]

    if cost > 150000 [ report 0.01 * cost ]
    ]

  report 0
end


;; whether buy-sell flow is intact or not ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report follow-chain [ first-link ]    ;;  first-link is an owner too

  ;; two ways to be intact : 1. a house on-sale without a seller (buy a total new house or house without owner)
  ;; 2. the buyer of house A is the owner of house B which is made an offer by seller (switch houses with the other person )

;  inspect self inspect first-link
;  user-message (word " if not is-house? made-offer-on [ report false ], and condition is  " not is-house? made-offer-on )

  if not is-house? made-offer-on [ report false ]  ;; if buyer's made-offer-on is not house (meaning buyer buy nothing, no deal), report false

  let seller [ my-owner ] of made-offer-on  ;; given the buyer offered on a real house, then set `my-owner` of the house being offered on to be `seller`

;  user-message ( word "if not (is-owner? seller ) [ report true ], can condition is " not is-owner? seller  )
;  stop-inspecting self stop-inspecting first-link
  if not (is-owner? seller ) [ report true ]  ;; if the `seller` is not an `owner` (meaning the house is vacant, deal right away ), report true


;  inspect first-link inspect seller user-message (word " check first-link with id " [who] of first-link word "check seller with id " [who] of seller )
  if first-link = seller [ report true ]  ;; given `sell` is an owner, if `first-link`  and  `seller` are the same owner, then the flow is intact.
                                          ;; This is confusing, but don't be. The following line solve the problem.

;  stop-inspecting first-link stop-inspecting seller
  report [follow-chain first-link ] of seller
  ;; given the buyer is not the seller (no match), now let's focus on the seller, run follow-chain under seller context,
  ;; meaning we are finding the owner of house which the seller made an offer on.
  ;; if the buyer and the seller of the house the older sell want to buy, are the same owner, then both buyer and older seller match a deal. flow is intact.

end

;; buyers are moving into new houses ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to move-house
 ;; move me to the house I am buying
 ;; then move the seller to their new house etc.

  let new-house made-offer-on  ;; under context of buyer or owner, save `made-offer-on` into `new-house`;

  if not (is-house? new-house) [ stop ] ;;if the `new-house` is not house, meaning buyer is not buying, then stop moving;

  let seller [ my-owner ] of new-house ;; assign `my-owner` of `new-house` into `seller`

  if is-owner? seller [ ;; if seller is an owner, calc the profit made by selling the house
    ; seller gets selling price to pay off mortgage or add to capital
    let profit [ sale-price ] of new-house - [ mortgage ] of seller ;; assign (sale-price - mortgage) to `profit`

    ask seller [ set mortgage 0 ] ;; set seller's mortgage to 0

    if profit > 0 [
      ; If sell made a profit, then add profit into seller's capital.
      ask seller [ set capital capital + profit ]

      ]
    ]

  ask new-house [ set my-owner myself ]  ;; since deal is made, change new-house owner to the buyer

  let duty stamp-duty-land-tax [ sale-price ] of new-house  ;; calc the duty payable with the new house sale-price
;  if duty > 0 [user-message(word "duty" duty)]

  ifelse [ sale-price ] of new-house > capital  ;; if the owner can't pay for the house in cash, s/he has to have a mortgage
    [
    ; borrow as much as possible, given owner's income and value of house, choose the smaller value of two calc formula
    set mortgage min (list (income * Affordability /
                                        ( interestPerTick * ticksPerYear * 100 ))
                           ([ sale-price ] of new-house * MaxLoanToValue / 100 ))

    set capital capital - int ([ sale-price ] of new-house - mortgage) - duty  ;; after paying rest with capital, the remaining still kept inside capital

    set repayment mortgage * interestPerTick /
            (1 - ( 1 + interestPerTick ) ^ ( - MortgageDuration * TicksPerYear ))  ;; calc repayment to pay back mortgage
    ]

    ; or if the buyer is a cash buyer, capital pays all, mortgage, repayment both are 0, and remaining still kept in capital
    [
    set mortgage 0
    set repayment 0
    set capital capital - [ sale-price ] of new-house - duty
    ]


  if capital < 0 [ set capital 0 ] ;; if buyer's capital is not enough for downpayment, set the negative remaining to 0.
  ;; but this no enuogh capital for down-payment should not happen, why here?

  show-turtle ; new entrants are not visible until now

  move-to new-house ;; move owner to where the new-house is

  set homeless 0 ;; set buyer's homeless period to 0

  set my-house new-house ;; set buyer's `my-house` to be the `new-house`

  set date-of-purchase ticks  ;; record the current ticks when the house is bought as `date-of-purchase`

  ask new-house [  ;; ask each new-house to put off market and make `offered-to` as nobody

    set for-sale? false
    set offered-to nobody
  ]

  set made-offer-on nobody ;; under buyer's context, buyer is not making any offer now

  ;; create a new record for the new deal, and save it into the house my-realtor sales list
  hatch-records 1 [  ;; create a new record under the buyer context

    hide-turtle  ;; make record invisible

    set date ticks  ;; record current ticks to be the `date` of record

    set the-house new-house  ;; assign the current `new-house` to be `the-house` of record

    set selling-price [sale-price] of new-house  ;; assign the `sale-price` of new-house to be `selling-price` of record

    ask [ my-realtor ] of new-house [ file-record myself ] ;; ask the new-house realtor to save record into its sales list

    ]
  set moves moves + 1  ;; count 1 more moving household into `moves`

  if is-owner? seller [ ask seller [ move-house ] ]  ;; if sell as owner exist, then ask seller to move-house too

end





to file-record [ the-record ]         ;; realtor procedure
  ; push this sales record onto the list of those I keep
  set sales fput the-record sales
end

to unfile-record [ a-house ]          ;; realtor procedure
  ; delete any record that mentions the house

;  set sales filter [ [the-house] of ? != a-house ] sales  ;; old-version
  set sales filter [ s -> [the-house] of s != a-house ] sales   ;; new-version

;  foreach sales [ x -> if [the-house] of x = a-house [ inspect x user-message ( word " a matched house in sales " )
;                                                       inspect a-house user-message (word "inspect a-house")  ] ]  ;; debugging
end

to demolish
  if is-owner? my-owner [ ;; under the context of the house, check the household is owner or not
    ask my-owner [ ;; if it is owner, set my-house nobody
      set my-house nobody

      set mortgage 0  ;; set mortgage and repayment to 0
      set repayment 0
      hide-turtle  ; set the owner invisible, meaning the owner is homeless
      ]
    ]

  ask realtors [ unfile-record myself ] ;; delete any record that mentions the house inside the sales of a realtor

;  set pcolor 57 ;; set the land to be muddy green

  set nDemolished nDemolished + 1 ;; add 1 upon nDemolished

  die  ;; make the house die
end



to-report gini-index [ lst ]
;; reports the gini index of the values in the given list
;; Actually returns the gini coefficient (between 0 and 1) - the
;; gini index is a percentage

  let sorted sort lst
  let total sum sorted
  let items length lst
  let sum-so-far 0
  let index 0
  let gini 0
  repeat items [
    set sum-so-far sum-so-far + item index sorted
    set index index + 1
    set gini  gini + (index / items) - (sum-so-far / total)
  ]
  ; only accurate if items is large
  report 2 * (gini / items)
end



to do-plots
;; draw a range of plots

  ;; plot income mean and median ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  set-current-plot "income averages"
  set-current-plot-pen "mean"
  plot mean [income] of owners with [ any? owners ] / 10000
  set-current-plot-pen "median"
  plot median [income] of owners with [any? owners ] / 10000



  ;; plot the number all-houses, empty-houses, buyers ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; count of total houses, empty houses, owners look for houses, houses with mortgage > sale-price
  set-current-plot "count houses owners"  ;; "Homes" must be defined in the interface
  set-current-plot-pen "houses"  ;; pen and its color must be defined inside interface
  plot count houses  ;; count all houses
  set-current-plot-pen "population"  ;; pen and its color must be defined inside interface
  plot count owners  ;; count all houses
  set-current-plot-pen "homeowners"  ;; pen and its color must be defined inside interface
  plot count owners with [ is-house? my-house ]  ;; count all houses


  set-current-plot "People In-Out House Demolished" ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  set-current-plot-pen "nExit"  ;; fixed proportion of owners die or exit the city every tick
  plot nExit
  set-current-plot-pen "nEntry" ;; fixed proportion of newcomer enter the city every tick
  plot nEntry
  set-current-plot-pen "nDemolished" ;;  the number of houses demolished due to too old or price too low
  plot nDemolished

  set-current-plot "People-discouraged-forced HousePrice-too-low" ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  set-current-plot-pen "nDiscouraged" ;; the number of owners discouraged to leave after being homeless too long
  plot nDiscouraged
  set-current-plot-pen "nForceOut"  ;; the number of owners can't afford repayment
  plot nForceOut
  set-current-plot-pen "nPrice<Mortgage"  ;; the number of houses whose sale-price is less than its owner's mortgage
  plot count houses with [ is-owner? my-owner and (sale-price  < [mortgage] of my-owner) ]

  set-current-plot "homeless, affordHouse, emptyHouse" ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  set-current-plot-pen "homeless" ;; the number of owners who have no house
  plot count owners with [ not is-house? my-house ]
  set-current-plot-pen "affordHouse"  ;; the number of owners who can afford a new house
  plot nOwnersOffered
  set-current-plot-pen "emptyHouse" ;; the number houses without owners
  plot count houses with [ not is-owner? my-owner ]

  set-current-plot "trade house up or down" ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  set-current-plot-pen "up"
  plot nUpShocked  ;; pot to track the number of owners who put their houses for sale due to rise of income
  set-current-plot-pen "down"
  plot nDownShocked   ;; pot to track the number of owners who put their houses for sale due to drop of income



  let houses-for-sale houses with [ for-sale?  and sale-price > 0 ]

  if any? houses-for-sale [  ;; if there are houses ready for sales

    set-current-plot "house for-sale distribution"  ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    set-plot-pen-interval 10000 ;; every time plot with 1000 units as distance
    set-plot-x-range 0 1000000  ;; set x range from 0 to 1000000
    set-current-plot-pen "for-sale"  ;; choose the pen named "For sale"
    histogram [ sale-price ] of houses-for-sale  ;; do histogram on sale-prices of all houses for sale


    set-current-plot "all house price distribution"  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    set-plot-pen-interval 10000 ;; every time plot with 1000 units as distance
    set-plot-x-range 0 1000000  ;; set x range from 0 to 1000000
    set-current-plot-pen "all"
    histogram [ sale-price ] of houses  ;; histogram of all houses

    set-current-plot "new sale-price distribution"  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    set-plot-pen-interval 10000 ;; every time plot with 1000 units as distance
    set-plot-x-range 0 1000000  ;; set x range from 0 to 1000000
    set-current-plot-pen "new-sales"
    histogram [ sale-price ] of houses-for-sale with [ date-for-sale = ticks ] ;; histogram of prices of houses currently enter markets
    ]

  if any? owners [
     set-current-plot "Income distribution for all"  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     set-plot-pen-interval 30000
     set-plot-x-range 1000 ifelse-value (max [income] of owners > 1E+5) [ 1E+6 ] [ 1E+5 ]
    set-current-plot-pen "all"
     histogram [ income ] of owners   ;; histogram of all owners' income

    ;; income distribution for those households who are ready to leave city due to being homeless too long
     set-current-plot "Income distribution for discouraged" ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     set-plot-pen-interval 30000
     set-plot-x-range 1000 ifelse-value (max [income] of owners > 1E+5) [ 1E+6 ] [ 1E+5 ]
     set-current-plot-pen "discouraged"
     histogram [ income ] of owners with [ homeless >= maxHomelessPeriod - 1 ]

;    set-current-plot "Income distribution for forced-out"
;     set-plot-pen-interval 30000
;     set-plot-x-range 1000 ifelse-value (max [income] of owners > 1E+5) [ 1E+6 ] [ 1E+5 ]
;     set-current-plot-pen "forced-out"
;     histogram [ income ] of owners with [ is-house? my-house and [for-sale?] of my-house and repayment * TicksPerYear > income ]
     set-current-plot "mean income of forced-out with 0-2 owners"  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     set-current-plot-pen "forced-out"
     plot meanIncomeForceOut  ;; plot the mean income of households who are forced to move out

    ;; Income distribution for those whose house price is less than mortgage
    set-current-plot "Income distribution for house price < mortgage" ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     set-plot-pen-interval 30000
     set-plot-x-range 1000 ifelse-value (max [income] of owners > 1E+5) [ 1E+6 ] [ 1E+5 ]
    set-current-plot-pen "price<mortgage"
    histogram [ income ] of owners with [ is-house? my-house and  [sale-price] of my-house  < mortgage ]

  ]


  set-current-plot "median sale vs sold price"  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ifelse any? houses-for-sale [
    set-current-plot-pen "For sale"
    plot medianPriceOfHousesForSale  ;; plot medianPrice of houses for sale
    ]
    [ plot 0 ]

  set-current-plot-pen "Sold"
  let medianSellingPriceOfHouses 0
  let houses-sold records  ;; make all records under temporary variable
  if any? houses-sold [ set medianSellingPriceOfHouses median [ selling-price ] of houses-sold ]
  plot medianSellingPriceOfHouses  ;; plot the median sold prices for all houses-sold




  ;; plot gini index on sold prices and owner incomes ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  set-current-plot "Gini index"
  set-current-plot-pen "Prices"
  if any? houses-sold [ plot gini-index [ selling-price ] of houses-sold ]  ;; plot gini-index on selling price of houses sold
  set-current-plot-pen "Incomes"
  if any? owners [ plot gini-index [ income ] of owners ]  ;; plot gini-index on owners income


  ;; plot owner's repayment / income ratio ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if any? owners [
    set-current-plot "Mortgage repayment / income"
;    if count owners with [ repayment > 0 ] = 0 [ user-message (word "how many owners left ? " count owners )] ;; debug when owners number shrink down to 0
    plot mean [ TicksPerYear * repayment / income ] of owners with [ repayment > 0 ]
    ]

  ;; plot median sold prices and median owner income ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if any? houses-sold and any? owners[
    set-current-plot "Median house price / Median income"
    plot medianSellingPriceOfHouses / median [ income ] of owners
    ]

  ;; plot the median duration of all houses on-sale ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if any? houses-for-sale [
    set-current-plot "Median time on market"
    plot median [ ticks - date-for-sale ] of houses-for-sale
    ]

 ;; plot each tick how many houses deals made or houses sold/bought ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  set-current-plot "Transactions"
  plot moves


  ;; plot interest rate and inflation rate ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  set-current-plot "Rates"

  set-current-plot-pen "Interest Rate"
  plot interestPerTick * TicksPerYear * 100

  set-current-plot-pen "Inflation Rate"
  plot Inflation


  ;; plot capital distribution of all owners ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if any? owners [
     set-current-plot "Capital distribution of all people"
     set-plot-pen-interval 5000
     set-plot-x-range 0 100000
     histogram [ capital ] of owners
     ]
end

;; two procedures to enable large numbers of owners to be added to, or removed from the market
;; for experimentation with the model
;;
;; to use, type into the command centre (for example):  make-owners 500
;;

to make-owners [ n ]
 ;; make some new owners arrive
  create-owners n [
    set color gray
    ; set initial income and savings
    assign-income
    ; new owners are not located anywhere yet
    hide-turtle
    ]
end

to kill-owners [ n ]
 ;; make some owners put their houses on the market and leave town
  ask n-of n owners with [ is-house? my-house ] [
    ask my-house [
      put-on-market
      set my-owner 0
      ]
    die
    ]
end
@#$#@#$#@
GRAPHICS-WINDOW
189
37
708
557
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
-16
16
-16
16
0
0
1
ticks
30.0

TEXTBOX
18
10
168
38
PwC Housing Market model\nversion 1.7
11
0.0
1

TEXTBOX
8
42
158
60
---Macro-economy ---
9
0.0
1

SLIDER
3
56
175
89
Inflation
Inflation
0
20
0.0
0.1
1
% pa
HORIZONTAL

SLIDER
3
91
175
124
InterestRate
InterestRate
0
20
3.0
0.1
1
% pa
HORIZONTAL

SLIDER
3
125
175
158
TicksPerYear
TicksPerYear
0
12
4.0
1
1
NIL
HORIZONTAL

SLIDER
3
159
175
192
CycleStrength
CycleStrength
0
80
0.0
5
1
%
HORIZONTAL

TEXTBOX
7
206
157
224
--- Owners ---
10
0.0
1

SLIDER
5
222
177
255
Affordability
Affordability
0
100
25.0
1
1
%
HORIZONTAL

SLIDER
5
256
177
289
Savings
Savings
0
100
50.0
1
1
%
HORIZONTAL

SLIDER
5
290
177
323
ExitRate
ExitRate
0
10
2.0
1
1
%
HORIZONTAL

SLIDER
5
324
177
357
EntryRate
EntryRate
0
10
5.0
1
1
%
HORIZONTAL

SLIDER
5
358
177
391
MeanIncome
MeanIncome
0
100000
30000.0
1000
1
pa
HORIZONTAL

SLIDER
6
393
178
426
Shocked
Shocked
0
100
20.0
1
1
%
HORIZONTAL

SLIDER
6
427
178
460
MaxHomelessPeriod
MaxHomelessPeriod
0
10
5.0
1
1
ticks
HORIZONTAL

TEXTBOX
9
461
159
479
0 means no limit
8
0.0
1

SLIDER
6
470
178
503
BuyerSearchLength
BuyerSearchLength
0
100
10.0
1
1
NIL
HORIZONTAL

TEXTBOX
7
505
157
523
---Realtors---
10
0.0
1

TEXTBOX
6
194
156
212
10 year exogenous interest rate cycle
8
0.0
1

SLIDER
6
518
178
551
RealtorTerritory
RealtorTerritory
0
50
8.0
1
1
NIL
HORIZONTAL

SLIDER
7
553
179
586
Locality
Locality
0
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
7
587
179
620
RealtorMemory
RealtorMemory
0
10
10.0
1
1
ticks
HORIZONTAL

SLIDER
7
622
179
655
PriceDropRate
PriceDropRate
0
10
3.0
1
1
%
HORIZONTAL

SLIDER
7
656
179
689
RealtorOptimism
RealtorOptimism
-10
10
3.0
1
1
%
HORIZONTAL

TEXTBOX
207
658
357
680
---Houses---
10
0.0
1

CHOOSER
712
451
883
496
InitialGeography
InitialGeography
"Random" "Gradient" "Clustered"
0

SLIDER
205
616
377
649
Density
Density
0
100
70.0
1
1
%
HORIZONTAL

SLIDER
623
614
886
647
HouseConstructionRate
HouseConstructionRate
0
1
0.33
0.01
1
% per tick
HORIZONTAL

SLIDER
377
575
544
608
HouseMeanLifetime
HouseMeanLifetime
1
500
100.0
1
1
years
HORIZONTAL

SLIDER
379
616
547
649
MaxLoanToValue
MaxLoanToValue
0
125
100.0
1
1
%
HORIZONTAL

SLIDER
718
578
885
611
MortgageDuration
MortgageDuration
0
100
25.0
1
1
years
HORIZONTAL

SWITCH
591
578
720
611
StampDuty?
StampDuty?
1
1
-1000

BUTTON
713
277
783
310
SETUP
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
713
311
782
344
Go
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

BUTTON
713
345
784
378
One Tick
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

PLOT
2066
310
2445
430
count houses owners
time
Number
0.0
0.0
750.0
0.0
true
true
"" ""
PENS
"houses" 1.0 0 -4079321 true "" ""
"population" 1.0 0 -5298144 true "" ""
"homeowners" 1.0 0 -13840069 true "" ""

PLOT
1611
36
2037
188
all house price distribution
Price
Number
0.0
100.0
0.0
20.0
true
false
"" ""
PENS
"all" 1.0 1 -16777216 true "" ""

PLOT
1589
497
2081
678
median sale vs sold price
time
NIL
0.0
10.0
60000.0
80000.0
true
true
"" ""
PENS
"For sale" 1.0 0 -5298144 true "" ""
"Sold" 1.0 0 -13345367 true "" ""

PLOT
1399
906
1651
1037
Mortgage repayment / income
time
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
1155
775
1397
906
Median time on market
time
ticks
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -14454117 true "" ""

PLOT
1666
915
2068
1035
Rates
time
%
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Inflation Rate" 1.0 0 -13345367 true "" ""
"Interest Rate" 1.0 0 -14439633 true "" ""

PLOT
1157
654
1586
774
Capital distribution of all people
NIL
Number
0.0
100000.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -955883 true "" ""

PLOT
1155
905
1397
1037
Transactions
time
Number
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
1397
774
1651
907
Median house price / Median income
time
NIL
0.0
10.0
0.0
4.0
true
false
"" ""
PENS
"p/e" 1.0 0 -5825686 true "" ""

PLOT
1666
793
2042
914
Gini index
time
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Incomes" 1.0 0 -16777216 true "" ""
"Prices" 1.0 0 -2674135 true "" ""

PLOT
2068
584
2411
712
trade house up or down
NIL
NIL
0.0
0.0
0.0
0.0
true
true
"" ""
PENS
"up" 1.0 0 -5298144 true "" ""
"down" 1.0 0 -14070903 true "" ""

SWITCH
713
381
816
414
debug?
debug?
1
1
-1000

CHOOSER
713
38
884
83
debug-setup
debug-setup
"none" "1 patches" "2 realtors" "2.5 build-a-house" "3 houses" "4 owners" "5 empty" "6 cluster" "7 quality" "9 realtors: my-houses, avg-price" "10 records" "11 paint-log-price"
0

SLIDER
713
417
885
450
price-difference
price-difference
1000
10000
5000.0
1000
1
NIL
HORIZONTAL

CHOOSER
714
87
884
132
debug-go
debug-go
"none" "s0 go-structure" "s1 count-owners" "s2 interestPerTick" "s3 interest-Cycle" "s4 inflation-income" "s5 owner-occupiers" "s6 income-shock" "s7 shock-sale" "s8 owners-gone" "s9 new-comers" "s10 discouraged-move-away" "s11 drop-sale" "s12 new-houses" "s13 remove-0-quality" "s14 value-houses" "s15 realtor-average-price" "s16 paint-house" "s18 valuation 1" "s19 valuation 2" "s20 make-offer part1" "s21 make-offer part2" "33 deal-move" "34 follow-chain" "35 move-house" "36 remove-records-offers-houses" "37 update-house-owner" "38 demolish"
0

TEXTBOX
197
14
487
42
red dot = existing owners, gray dot = new comers
11
0.0
1

SLIDER
714
135
886
168
house-alpha
house-alpha
1
255
251.0
10
1
NIL
HORIZONTAL

MONITOR
2067
963
2157
1008
tick interest %
interestPerTick * 100
2
1
11

MONITOR
2068
918
2155
963
NIL
InterestRate
17
1
11

SLIDER
712
499
884
532
income-shock
income-shock
0
50
20.0
1
1
%
HORIZONTAL

CHOOSER
714
169
884
214
scenario
scenario
"base-line" "raterise 3" "raterise 7" "raterise 10" "influx" "influx-rev" "poorentrants" "ltv"
4

PLOT
1666
671
2032
791
income averages
ticks
w
0.0
0.0
0.0
0.0
true
true
"" ""
PENS
"mean" 1.0 0 -5825686 true "" ""
"median" 1.0 0 -13791810 true "" ""

CHOOSER
713
216
863
261
exp-options
exp-options
"none" "track-owner-numbers" "track-houses-sales-numbers" "house" "realtor"
0

PLOT
2066
35
2452
155
People In-Out House Demolished
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"nExit" 1.0 0 -5298144 true "" ""
"nEntry" 1.0 0 -13345367 true "" ""
"nDemolished" 1.0 0 -11053225 true "" ""

PLOT
2066
156
2470
306
People-discouraged-forced HousePrice-too-low
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"nDiscouraged" 1.0 0 -16777216 true "" ""
"nForceOut" 1.0 0 -5298144 true "" ""
"nPrice<Mortgage" 1.0 0 -14439633 true "" ""

PLOT
2067
432
2448
582
homeless, affordHouse, emptyHouse
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"homeless" 1.0 0 -16777216 true "" ""
"affordHouse" 1.0 0 -5298144 true "" ""
"emptyHouse" 1.0 0 -13840069 true "" ""

PLOT
1611
190
2036
340
house for-sale distribution
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
"for-sale" 1.0 1 -14439633 true "" ""

PLOT
1614
343
2041
493
new sale-price distribution
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
"new-sales" 1.0 1 -5825686 true "" ""

PLOT
1158
38
1599
188
Income distribution for all
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
"all" 1.0 1 -16449023 true "" ""

PLOT
1159
192
1599
342
Income distribution for discouraged
NIL
NIL
0.0
0.0
0.0
0.0
true
false
"" ""
PENS
"discouraged" 1.0 1 -2674135 true "" ""

PLOT
1137
345
1597
495
mean income of forced-out with 0-2 owners
NIL
NIL
0.0
0.0
0.0
0.0
true
false
"" ""
PENS
"forced-out" 1.0 0 -13840069 true "" ""

PLOT
1159
498
1596
648
Income distribution for house price < mortgage
NIL
NIL
0.0
0.0
0.0
0.0
true
false
"" ""
PENS
"price<mortgage" 1.0 1 -8630108 true "" ""

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

my-house
false
0
Line -7500403 true 255 105 150 15
Line -7500403 true 45 255 45 105
Line -7500403 true 45 255 255 255
Line -7500403 true 255 255 255 105
Line -7500403 true 150 15 45 105
Polygon -7500403 true true 150 15 255 105 255 255 45 255 45 105 150 15

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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
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
