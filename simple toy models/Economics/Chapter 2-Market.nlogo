;; updated, modified and commented by 深度碎片
;; originally written by Nigel
;; original models to be downloaded from Gilbert http://cress.soc.surrey.ac.uk/web/publications/books/agent-based-modelling-economics/more-information


globals [

  fruit-and-veg                                             ;; all items to buy or sell

  fruit-and-veg-prices                                      ;; whole-sale prices for all items

  mean-items                                                ;; average number of items for what???

]

breed [shoppers shopper]                                    ;; agent type 1: shopper
breed [traders trader]                                      ;; agetn type 2: trader

shoppers-own [                                              ;; shopper attributes

  shopping-list                                             ;; shopping list attribute

  not-yet-visited                                           ;; not-yet-visited traders attribute

  spent                                                     ;; the amount of money spent attribute
]

traders-own [                                               ;; trader attributes

  stock                                                     ;; the items a trader stores
  prices                                                    ;; the prices a trader sell items
]

;--------------------------------------------------
to setup
  clear-all



  set fruit-and-veg [                                        ;; list of all fruit and veg
    "apples" "bananas" "oranges" "plums" "mangoes" "grapes"

    "cabbage" "potatoes" "carrots" "lettuce" "tomatoes" "beans"]

  set fruit-and-veg-prices n-values (length fruit-and-veg) [1 + random 100]
                                                             ;; set whole-sale prices for each type of items

  let xs [-12 -9 -6 -3 0 3 6 9 12]                           ;; positions of a row of stalls (fixed is realistic)

  foreach xs [ s ->                                          ;; create trader one by one based on locations

    create-traders 1 [                                       ;; create a single trader
      set shape "house"                                      ;; set it a house-shape
      setxy s 0                                              ;; locate it at (s, 0)
      set color red                                          ;; set color red

      set stock n-of n-items-stocked fruit-and-veg           ;; give each trader some types of produce to sell
      set prices []                                          ;; set attribute prices an empty list
      let mark-up (1 + random 30) / 100                      ;; individual price raise by percentage
      foreach stock [ x ->                                   ;; create individual price item by item and save in prices list

        set prices lput ((1 + mark-up) * (item (position x fruit-and-veg) fruit-and-veg-prices)) prices
      ]
    ]
  ]

  create-shoppers n-shoppers [                               ;; create a number of shoppers
    set shape "person"                                       ;; set person shape
    setxy random-pxcor random-pycor                          ;; locate randomly
    set color yellow                                         ;; set yellow color
    set not-yet-visited traders                              ;; set not-yet-visited to be full trader agentset

    set shopping-list n-of (1 + random 8) fruit-and-veg      ;; give each shopper a random list of produce to buy
  ]

  set mean-items mean [ length shopping-list] of shoppers    ;; calc average length of shopping list

  reset-ticks

end

to go

  ; ask each shopper to scan for the cheapest sequence of stall to visit
  ; and then visit those stalls

  ask shoppers [                                             ;; ask each shopper
    let route search-before-buying                           ;; find the cheapest stalls to buy
    foreach route [ r ->                                     ;; loop each cheapest stall
      let stall r                                            ;; use local var stall represent each cheapest stall


      face stall                                             ;; face that stall
      while [ patch-here != [patch-here] of stall ]          ;; while shopper and stall are not on the same patch
         [ forward 0.005 * walking-speed ]                   ;; make shopper walk distance of 0.005 * walking-speed
                                                             ;; make sure not walk past

      set not-yet-visited not-yet-visited with [ self != stall ]
                                                             ;; leave the visited stall out and save the rest in not-yet-visited




      let purchases buy-from-stall shopping-list stall       ;; buy everything on my shopping-list that is for sale at this stall

      foreach purchases [ p ->                               ;; take each purchased item
        set spent spent + produce-price p stall              ;; add such purchased item's price to spent
        set shopping-list remove p shopping-list             ;; remove the item from the shopper's shopping list
      ]

      if empty? shopping-list [ set ycor -16 ]               ;; when shopping is done, move itself to the edge (home)
    ]
  ]


  set mean-items mean [ length shopping-list] of shoppers    ;; calculate the average number of items on the shopping lists

  ; count the iterations
  tick


  if mean-items = 0  [ stop ]                                ;; if no one has anything left to buy, stop

end

to-report search-before-buying                               ;; to find which group of stalls providing the cheapest cost in
                                                             ;; total for all items of shopping list
                                                             ;; we don't worry about which stall provide the cheapest prices


  let cheapest-price 100000                                  ;; initialise cheapest with a very large number
                                                             ;; so every purchase will be cheaper
  let cheapest-route []                                      ;; make empty list for cheapest stalls (traders)

  repeat n-scans [                                           ;; loop a number of times

                                                             ;; each loop initialize the containers ;;;;;;;;;;;;;;;;
    let this-route []                                        ;; rout-chosen for this loop as empty list
    let cost 0                                               ;; initialize cost 0
    let to-buy shopping-list                                 ;; local var to-buy to be entire shopping list
    let visited []                                           ;; local var visited as empty list

                                                             ;; loop until the shopping-list is done ;;;;;;;;;;;;;;;;
    while [ not empty? to-buy] [                             ;; loop while to-buy is not empty

      let stall one-of traders with [ not member? self visited ]
                                                             ;; choose one of the not-yet-visited stalls

      if stall = nobody [                                    ;; if the stall is nobody, then it sells no items on the list
        show (word "Trying to buy " to-buy ", but no trader sells it.")
        set shopping-list []                                 ;; set shopping-list empty list ??
        report []                                            ;; return or report empty list as cheapest stalls ??
      ]

      set visited lput stall visited                         ;; put the current stall into visited list

      let purchases buy-from-stall to-buy stall              ;; find all items can be bought from this stall  ??

      if not empty? purchases [                              ;; if the stall does offer items on to-buy list
        set this-route lput stall this-route                 ;; put this stall into this-route

        foreach purchases [ p ->                             ;; loop each item can be purchased at this stall
          set cost cost + produce-price p stall              ;; add the stall price for the item to the cost

          set to-buy remove p to-buy                         ;; remove the item from the to-buy list
        ]
      ]
    ]                                                        ;; when this while loop is done, a number of stalls chosen,
                                                             ;; which together offer all items on the shopping list
                                                             ;; cost is the prices of the shopping list item added together

                                                             ;; keep track of the lowest cost and the cheapest route of stalls
    if cost < cheapest-price [                               ;; by now, the shopping-list may or may not finished
                                                             ;; cost is all added up
                                                             ;; if cost < cheapest-price (initialized as 10000)
      set cheapest-price cost                                ;; update cheapest-price with cost value
      set cheapest-route this-route                          ;; update cheapest-route with this-route
    ]
  ]
  report cheapest-route                                      ;; report the latest cheapest-route
end

to-report produce-price [ produce stall ]                    ;; to get the price of an item from a stall

  report item (position produce [stock] of stall) [ prices ] of stall
                                                             ;; find position of item in the stock of stall, then
                                                             ;; find the price of the position in prices of the stall
end

to-report buy-from-stall [ what-to-buy stall ]               ;; report the items list that the stall offer compared to what-to-buy list

  report filter [ x -> member? x [stock] of stall ] what-to-buy

end

to run-experiment
  set n-scans 1
  let runs-per-trial 100
  while [ n-scans <= 10 ] [
    let total-of-averages 0
    repeat runs-per-trial [
      ; reset the shoppers' lists and amount spent
      ask shoppers [
        set not-yet-visited traders
        ; give each shopper a random list of produce to buy
        set shopping-list n-of (1 + random 8) fruit-and-veg
        set spent 0
      ]
      go
      set total-of-averages total-of-averages + mean [ spent ] of shoppers
    ]
    show (word "Mean of average of cost of shopping lists over " runs-per-trial " runs for " n-scans " scans = " (total-of-averages / runs-per-trial))
    set n-scans n-scans + 1
  ]
  show "Finished."
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
1
1
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

SLIDER
20
95
205
128
n-shoppers
n-shoppers
0
20
15.0
1
1
NIL
HORIZONTAL

BUTTON
27
34
93
67
NIL
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
125
35
188
68
NIL
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

SLIDER
20
150
205
183
Walking-speed
Walking-speed
0
5
0.5
0.5
1
NIL
HORIZONTAL

MONITOR
20
250
205
295
Mean number of items left to buy
mean-items
2
1
11

SLIDER
20
205
205
238
n-items-stocked
n-items-stocked
1
10
4.0
1
1
NIL
HORIZONTAL

PLOT
20
310
205
465
Spending
Ticks
Amount
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [ spent ] of shoppers"

SLIDER
17
485
202
518
n-scans
n-scans
1
10
5.0
1
1
NIL
HORIZONTAL

MONITOR
210
485
387
530
Average spend
mean [ spent ] of shoppers
2
1
11

@#$#@#$#@
## WHAT IS IT?

This model demonstrates how to build a simple agent-based simulation of a basic market.

## HOW IT WORKS

There are market trader and shopper agents in the model.  The traders (red house icons) each run a fruit and vegetable market stall, and the shoppers (yellow people icons) have shopping lists of items that they want to buy from the market.  Traders offer their wares at the price that they set and may stock only a limited range of produce.  Shoppers choose which stall to buy from, and then purchase all or some of their requirements from that stall.  

The different versions of the model described in Chapter 2 include successively more complicated rules for shoppers to choose which market stalls to buy from.  

## HOW TO USE IT

To use the model, first select the number of shoppers to simulate, and how quickly they walk from stall to stall (varying the latter just changes the speed at which things happen) using the sliders on the interface.  Then set the number of items (different fruits and vegetables) that each trader has on their stall. Press the Setup button to create the agents and then press the Go button to run the model.

## THINGS TO NOTICE

Notice that if the traders don't stock many items, it is possible for a shopper to fail to find an item on their shopping list, becuase no trader stocks it (such problems are reported in the Command Centre at the bottom of the Interface).


## CREDITS AND REFERENCES

Runs on NetLogo 5.2.

For more information, see Hamill, L. & Gilbert, N. (2016) Agent-based Modelling in Economics. Wiley: Chapter 2.

To refer to this model: Hamill, L. & Gilbert, N. (2016) Market model.
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
1
@#$#@#$#@
