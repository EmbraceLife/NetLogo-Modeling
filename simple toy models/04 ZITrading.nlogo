;; Implements Zero-intelligence trading based on the article
;; by Gode and Sunder.  The code implements the simple order
;; book trading described in Gode & Sunder (1993), pp. 121-122.

;; Developed by:
;; Mark E. McBride
;; Department of Economics
;; Miami University
;; Oxford, OH 45056
;; mark.mcbride@miamioh.edu
;; http://memcbride.net/
;; http://www.memcbride.net/labs/
;; Last updated:  January 2, 2014
;; code to be downloaded from https://github.com/memcbride/ZITrading

;; define the two types of agents
breed [buyers buyer]
breed [sellers seller]
;; define specialized turtles
breed [data datum]

;; define the variables local to each type of agent
buyers-own [value traded? price]
sellers-own [cost traded? price]
;; define the variables local to specialized turtles
data-own [Price]

;; globals
globals [transactionPrice ;; last transaction price
         tickcount        ;; number of times simulation has run
         maxSurplus       ;; maximum surplus possible from market
         actualSurplus    ;; surplus extracted by trades
         efficiency       ;; market efficiency
         traders          ;; agentset of all buyers and sellers
         bestBid          ;; current best Bid
         bestBidID        ;; buyer with current best bid
         bid?             ;; bid available?
         bestAsk          ;; current best Ask
         bestAskID        ;; seller with current best ask
         ask?             ;; ask available?
         predictedq       ;; predicted market q
         predictedp       ;; predicted market p
        ]

;; setup the environment for a single simulation run
to setup
  ;; clear out all previous variables
  clear-all
  ;; populate the patches with the number of each agents randomly
    ask n-of numberOfBuyers patches [
      sprout-buyers 1 [init-buyer]
      ]
    ask n-of numberOfSellers patches [
      sprout-sellers 1 [init-seller]
      ]
  ;; plot the demand-supply curves
    ;;create-demand-supply
  ;; calculate the max surplus in this market
    calc-max-surplus
  ;; initialize actual surplus
    set actualSurplus 0.0
  ;; initialize the orderbook
    init-orderBook
  ;; create traders agentset
    set traders turtles with [breed = buyers or breed = sellers]
  ;; reset the tickcount
    reset-ticks
  ;; draw supply and demand curve
  create-demand-supply
  end

;; restore the default parameters
to restore-defaults
    set numberOfBuyers 50
    set numberOfSellers 50
    set maxNumberOfTrades 2000
    set maxBuyerValue 200.0
    set maxSellerCost 200.0
    set constrained true
    ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  clear-all
  reset-ticks
  end

;; main loop
to go
  ;; end the simulation??
  if ticks = maxNumberOfTrades [
    draw-histogram-prices
    stop ]
  ;; execute a trade
    doTrade
  ;; update the clock
    tick
  end

;; initialize buyer
to init-buyer
    set color black   ;; set so does not show in world view
    set value random-float maxBuyerValue
    set traded? false
    ;; print out the buyer information
    ;; show value
  end

;; initialize seller
to init-seller
    set color black  ;; set so does not show in world view
    set cost random-float maxSellerCost
    set traded? false
    ;; print out the seller information
    ;; show cost
  end

;; initialize the orderBook
to init-orderBook
    set bestBid 0.0
    set bestBidID nobody
    set bid? false
    set bestAsk maxSellerCost
    set bestAskID nobody
    set ask? false
  end

;; buyer form bid-price
;; ZI-C buyer, thus bid-price is between zero and buyer-value
to-report formBidPrice
  ifelse constrained
    ;; ZI-C:  buyers will not bid above their buyer value
    [ report value - (random-float 1) * (value - 1) ]
    ;; ZI-U:  buyers will bid up to the maxBuyerValue even if above their buyer value
    [ report (random-float 1) * (maxBuyerValue - 1) ]
  end

;; seller form ask-price
;; ZI-C seller, thus ask-price is between seller cost and max
;; possible price given market, i.e., maxBuyerValue
;; ZI-U seller is between maxBuyerValue and lowest possible seller cost
to-report formAskPrice
  ;; if cost > maxBuyerValue [show "seller has cost =" + cost  + "> maxBuyerValue"]
  ifelse constrained
    ;; ZI-C:  sellers will not ask below their seller cost
    [ report cost + (random-float 1) * abs ((maxBuyerValue - cost)) ]
    ;; ZI-U:  sellers may ask below their seller cost
    [ report (random-float 1) * (maxSellerCost - 1) ]
  end

;; identify potential traders and see if they'll trade
to doTrade
    let bidID 0
  let bidPrice 0
  let askID 0
  let askPrice 0
  let transPrice 0
  let tradeID 0

    ;; init transPrice
    set transPrice 0.0
    ;; randomly select a buyer or seller who has not traded
    set tradeID one-of traders with [traded? = false]
    ;; determine if there was anybody left to trade
    if tradeID = nobody [ stop ]
    ;; determine if trader is a buyer or seller
    ask tradeID [
      ifelse breed = buyers
        ;; process a buyer
        [ ;; get bid price
          set bidPrice [formBidPrice] of tradeID
          ;; show "sets bidPrice = " + bidPrice
          ;; type tradeID type " bids " type bidPrice type " with value " type value type "\n"
          ;; is there an ask to trade with and is bidPrice > askPrice
          ifelse ask? and (bidPrice > bestAsk)
            ;;  bid > current best Ask, trade takes place
            [ ;; type "Trade!! " type "Bid=" type bidPrice type " bestAsk=" type bestAsk type "\n"
              set transPrice bestAsk
              ;; update buyer
              ask tradeID [set traded? true
                           set price transPrice]
              ;;set [ traded? ] of tradeID true
              ;;set [price] of tradeID transPrice
              ;; update seller
              ask bestAskID [set traded? true
                             set price transPrice]
              ;;set [traded?] of bestAskID true
              ;;set [price] of bestAskID transPrice
              ;; update globals, data, and graphs
              set transactionPrice transPrice
              set actualSurplus (actualSurplus + [value] of tradeID - [cost] of bestAskID)
              set efficiency (actualSurplus / maxSurplus) * 100
            ]
            ;; bid < current best Ask (or no current Ask)
            [ ;; is the bidPrice > current best bid?
              if bidPrice > bestBid
              [ ;; reset the bestBid
                set bid? true
                set bestBid bidPrice
                set bestBidID tradeID
                ;; type "Best bid reset to " type bestBid type "\n"
              ]
            ]
        ]
        ;; process a seller
        [ ;; get ask price
          set askPrice [formAskPrice] of tradeID
          ;; show "sets askPrice = " + askPrice
          if (askPrice < cost) and (constrained)
            [ show "Seller ask below cost with ZI-C"
            ]
          ;; type tradeID type " asks " type askPrice type " with cost " type cost type "\n"
          ;; is there a bid to trade with and is bidPrice > askPrice
          ifelse bid? and (bestBid > askPrice)
            ;; current best bid > ask, trade takes place
            [ ;; type "Trade!! " type "Ask=" type askPrice type " bestBid =" type bestBid type "\n"
              set transPrice bestBid
              ;; update buyer
              ask bestBidID [set traded? true
                             set price transPrice]
              ;;set [traded?] of bestBidID true
              ;;set [price] of bestBidID transPrice
              ;; update seller
              ask tradeID [set traded? true
                           set price transPrice]
              ;set [traded?] of tradeID true
              ;set [price] of tradeID transPrice
              ;; update globals, data, and graphs
              set transactionPrice transPrice
              set actualSurplus (actualSurplus + [value] of bestBidID - [cost] of tradeID)
              set efficiency (actualSurplus / maxSurplus) * 100
            ]
            ;; current best bid < ask (or no current Bid)
            [ ;; is the askPrice < current best ask?
              if askPrice < bestAsk
              [ ;; reset the bestAsk
                set ask? true
                set bestAsk askPrice
                set bestAskID tradeID
                ;; type "Best ask reset to " type bestAsk type "\n"
              ]
            ]
        ]
    ]
    ;; if trade occurred, update displays and globals
    if transPrice > 0.0
      [ create-data 1 [set price transPrice]
        draw-transaction
        ;; trade occurred so reset orderbook (page 122 G&S)
        init-orderBook
      ]
  end

;; calculate the maximum possible surplus from market
;; and calculate predicted equilibrium
to calc-max-surplus
    let bids 0
  let asks 0
  let surpluses 0

    set surpluses 0.0
  ;; grab the sorted bids
    set bids sort-by [ [?1 ?2] -> ?1 > ?2 ] [value] of buyers
  ;; grab the asks
    set asks sort-by [ [?1 ?2] -> ?1 < ?2 ] [cost] of sellers
  ;; we now have a list of bids sorted from highest to lowest
  ;; and a list of asks sorted from lowest to highest
  ;; now shorten either bids or asks based on which has fewest
    if (numberOfBuyers != numberOfSellers) [
      ifelse (numberOfBuyers < numberOfSellers)
        [ set asks sublist asks 0 (numberOfBuyers) ]
        [ set bids sublist bids 0 (numberOfSellers) ]
      ]
  ;; sum the positive surpluses for the sorted
  ;; pairwise bids and asks from highest to lowest;
  ;;  (foreach bids [show "bid="+ ?1])
  ;;  (foreach asks [show "ask="+ ?1])
    set predictedq 0
    set predictedp 200
    (foreach bids asks [ [?1 ?2] ->
      if ( ?1 - ?2 > 0.0) [
      set predictedq predictedq + 1
      set predictedp (?1 + ?2) / 2
      set surpluses (surpluses + ?1 - ?2) ]
      ;; show (word "bid = " ?1 " ask = " ?2 " surplus = " surpluses " q= " predictedq " p= " predictedp)
      ]
     )
   ;; now sum the positive surpluses to get maxSurplus
     set maxSurplus surpluses
;     show "maxSurplus - " + maxSurplus
  end

;; draws the demand-supply curves for the values
to create-Demand-Supply
  ;; set plot to plot to
    set-current-plot "Demand-Supply"
  ;; set pen to draw demand curve
    set-current-plot-pen "demand-pen"
  ;; draw the demand curve
    foreach sort-by [ [?1 ?2] -> [value] of ?1 > [value] of ?2 ] buyers
      [ ?1 -> plot [value] of ?1 ]
  ;; set pen to draw supply curve
    set-current-plot-pen "supply-pen"
  ;; draw the supply curve
    foreach sort-by [ [?1 ?2] -> [cost] of ?1 < [cost] of ?2 ] sellers
      [ ?1 -> plot [cost] of ?1 ]
  end

;; draws the transactions on the demand-supply curves
to draw-transaction
  ;; set plot to plot to
    set-current-plot "Demand-Supply"
  ;; set pen to draw transactions
    set-current-plot-pen "transactions-pen"
  ;; draw the current transaction price
    plot transactionPrice
  end

;; draws the histogram of the transaction prices
to draw-histogram-prices
  ;; set plot to plot to
    set-current-plot "Price Dispersion"
  ;; draw the histogram of transaction prices
    histogram [price] of data
  end

;; Copyright and License
;; See the Info tab.

;; revision history
;;
;;  January 18 2014
;;
;;  Updated Time monitor on main window to correctly display the
;;  number of ticks.
;;
;;  January 2 2014
;;
;;  Updated to work in Version 5.0.5 of Netlogo.
;;
;;  January 10 2007
;;
;;  Completely changed the trading mechanism to reflect the simple
;;  order book approach actually described in Gode & Sunder (1993)
;;  on pages 121-122.
;;
;;  Added a constrained switch to implement either ZI-C or ZI-U
;;  agents in the model.
;;
;;  Dropped the Price display window, which was displaying the last
;;  transaction price.  The average price window conveys the
;;  appropriate information.
;;
;;  Setup the default parameters for maxBuyerValue and maxSellerCost
;;  to be consistent with G&S article.  Number of buyers and sellers
;;  is still considerably higher than the original article.
;;
;;  September 26 2006
;;
;;  Fixed a bug when the number of buyers and sellers were unequal.
;;  The program would abort with an error in the foreach block that
;;  calculated max possible surplus.
;;
;;  August 18 2006
;;
;;  Adjusted the way the ZI-C bid and ask prices were being randomly set
;;  Gode and Sunder state in their article that the bid and
;;  ask prices are randomly set (uniform distribution) between
;;  1 and 200 which was the range of possible trading prices.
;;  This would be true for ZI-U traders.  This version now
;;  sets the ask price between the sellers cost and the
;;  maxBuyerValue (incorrectly setting it to maxSellerCost
;;  before), i.e., a ZI-C seller that can't lose money based
;;  on its ask-price.  The buyer sets it random bid between
;;  the buyer value and the minimum seller cost 1 (incorrectly
;;  set to zero before), i.e., a ZI-C buyer.
;;
;;  August 17 2006
;;
;;  Changed the world view show that turtles do not show.
;;  This was done to reduce confusion about whether something
;;  should be happening in the world view.
@#$#@#$#@
GRAPHICS-WINDOW
349
10
765
67
-1
-1
8.0
1
10
1
1
1
0
1
1
1
0
50
0
5
0
0
1
ticks
30.0

SLIDER
150
10
322
43
numberOfBuyers
numberOfBuyers
10
200
40.0
10
1
NIL
HORIZONTAL

SLIDER
150
43
322
76
numberOfSellers
numberOfSellers
10
200
50.0
10
1
NIL
HORIZONTAL

SLIDER
150
77
322
110
maxBuyerValue
maxBuyerValue
1
200
199.0
1
1
NIL
HORIZONTAL

SLIDER
150
111
322
144
maxSellerCost
maxSellerCost
1
200
200.0
1
1
NIL
HORIZONTAL

SLIDER
150
144
322
177
maxNumberOfTrades
maxNumberOfTrades
200
10000
2000.0
200
1
NIL
HORIZONTAL

BUTTON
47
197
113
230
Setup
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
341
199
406
232
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

PLOT
426
179
761
517
Demand-Supply
Quantity
Price
0.0
40.0
0.0
40.0
true
false
"" ""
PENS
"supply-pen" 1.0 0 -2674135 true "" ""
"demand-pen" 1.0 0 -13345367 true "" ""
"transactions-pen" 1.0 0 -16777216 true "" ""

BUTTON
616
112
681
145
Reset
restore-defaults
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
5
438
64
483
Volume
count data
0
1
11

MONITOR
62
438
133
483
Avg Price
mean [price] of data
2
1
11

MONITOR
132
438
191
483
Std Dev
standard-deviation [price] of data
2
1
11

MONITOR
700
104
757
149
Time
ticks
0
1
11

TEXTBOX
5
88
147
109
Step 1:  Select Parameters
11
0.0
0

TEXTBOX
5
169
143
187
Step 2:  Setup the model
11
0.0
0

PLOT
5
264
219
427
Price Dispersion
Price
# of Trades
0.0
200.0
0.0
5.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

PLOT
226
264
422
428
Market Efficiency
# of Trades
Efficiency
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot efficiency"

MONITOR
190
438
251
483
Efficiency
efficiency
2
1
11

TEXTBOX
158
190
339
246
Step 3:  Go\nStep 4:  To pause press Go again\nStep 5:  To run simulation again, got to step 1
11
0.0
0

TEXTBOX
511
115
607
143
Reset parameters to defaults
11
0.0
0

SWITCH
343
109
476
142
Constrained
Constrained
0
1
-1000

MONITOR
305
441
363
486
Pred. Q
predictedq
0
1
11

MONITOR
363
441
420
486
Pred. P
predictedp
2
1
11

@#$#@#$#@
## WHAT IS IT?

Experimental economics has a long tradition of placing human subjects in simulated double auction markets.  The results of the double-auction experiments consistently support that human agents can achieve high levels of market efficiency quickly (through few rounds of trading) and even in relatively thin markets (few buyers and sellers).  Gode and Sunder (1993) conducted experiments comparing human agents with zero-intelligence artificial agents in double-auction markets and found that the zero-intelligence agents can lead to high levels of market efficiency even given their random decision making.  They concluded that rationality is not a necessary assumption for the market to achieve efficiency and that the market institution provides the first order effect on market efficiency.

## HOW IT WORKS

Gode and Sunder (1993) implement a simplified order book mechanism in a double auction market.  As described in their paper: "We made three choices to simplify our implementation of the double auction.  Each bid, ask, and transaction was valid for a single unit.  A transaction canceled any unaccepted bids and offers.  Finally, when a bid and ask crossed, the transaction price was equal to the earlier of the two." (p. 122).  Thus there are four possible current states of the order book:  a) no best ask (lowest ask price) nor a best bid (highest bid price); b) a best ask and no best bid; c) no best ask but a best bid; or d) both a best ask and best bid.  Note that the best ask will be greater than the best bid in case (d) and that there is at most one best ask and one best bid on the order book at any time.

The model implements both the zero-intelligence constrained (ZI-C) traders and the zero-intelligence unconstrained (ZI-U) traders from Gode and Sunder via the constrained switch.  The ZI-C traders cannot make a trade that will yield a negative profit, i.e., buyers cannot buy at a price higher than their buyer value and sellers cannot sell for a price below their seller cost.  However, the ZI-U traders can make a trade that yields negative profits.

In the zero-intelligence trader model, buyers are randomly assigned buyer values between zero and maxBuyerValue.  Sellers are randomly assigned seller costs between zero and maxSellerCost.  In each tick of the clock, either a buyer or seller is randomly selected.  A buyer randomly forms a bid price between his buyer value and 0 (ZI-C), or between maxBuyerValue and 0 (ZI-U).  A seller randomly forms an ask price between his seller cost and maxBuyerValue (ZI-C) or between 0 and the maxBuyerValue (ZI-U).  A selected buyer then compares his bid to the current state of the order book. If his bid is above the best ask, he accepts the best ask and the buyer and the seller who made the best ask then trade at the best ask.  The order book is then emptied.  If the buyer's bid is below the best ask (or there is no best ask) and there is no best bid, it becomes the best bid.  If the buyer's bid is below the best ask (or there is no best ask) and above the best bid, it replaces the best bid.  If the buyer's bid is below the best bid, his bid is ignored.  Analagous actions occur if the selected trader is a seller by comparing their randomly formed ask to the current order book.  If the selected seller makes an ask below the best bid, a trade occurrs with the best bid at the best bid price.  After selecting a buyer or seller, if a trade occurred then the involved buyers and sellers are removed from the market since each buyer and seller can only trade one unit.  The process continues unitl maxNumberOfTrades is reached.

## HOW TO USE IT

To run the model, select the numbers of buyers and sellers, their respective maximum value and cost, the maximum number of trades and whether the traders are ZI-C or ZI-U.  Next press the setup button to initialize the model.  The supply and demand graphs are drawn and the agents are placed on the landscape.  The agents do not move around or use the landscape in any significant way.  THe go button starts the simulation.  When a trade occurs, the transaction price is graphed on the demand-supply diagram and the market statistics are updated.  The model will automatically stop when the maxNumberOfTrades is reached.  The model can be stopped earlier by click the go button again.

Here's a more complete description of each interface element:

Buttons:  
go:
    starts the model running

setup: clears out any previous runs, initializes all variables, and creates the buyers and sellers

reset: resets all sliders to their default values

Sliders:  
numberOfBuyers:
    number of buyers ranging from 10 to 200

numberOfSellers:   number of sellers ranging from 10 to 200

maxBuyerValue:
     maximum value a buyer may have ranging from 1 to 200

maxSellerCost:
     maximum cost a seller may have ranging from 1 to 200

maxNumberOfTrades: the number of POTENTIAL random matches between buyers and sellers the simulation will attempt

Switches:  
contrained:   on -> ZI-C traders, off -> ZI-U traders

Graphs:  
Supply-Demand Graph: Displays the demand-supply graph from the randomly generated agents using the parameters from the sliders and the transaction price for each trade

Price Dispersion:
    Shows a histogram of the transaction prices at the end of the model run

Market Efficiency:   Show the market efficiency of the trades.  Market efficiency is defined as actual surplus generated over maximum potential surplus given the supply and demand curves

Monitors:  
time:
       current tick count of the model when running

Volume:
     number of trades 

Avg Price:  average of the transaction prices

Std Dev:
    standard deviation of the transaction prices

Efficiency: market efficiency (see definition above)

## THINGS TO NOTICE

How do transaction prices and quantity emerge?  You can check the predicted equilibrium price and quanityt by hovering the mouse pointer over the intersection of the demand and supply curve in the graph.  Do the observed transaction prices and volumes approach the predicted values?  How quickly?

What level of market efficiency arises?  Are the results fully efficient?  What might lead to the result your finding?

How much dispersion is there in the transaction prices?  Are they centered around the average price or is the distribution flatter?  multiple peaks?

How does the number of trading rounds affect the predictions of the model?  Is average price close to the competitive equilibrium?  Is the standard deviation of prices smaller?

How does the number of buyers and sellers affect the predictions of the model?  Is average price get closer to the competitive equilibrium as the number of buyers and sellers get large?  Is the standard deviation of prices smaller?

How do each of the above change if your traders are not budget constrained, i.e., they are ZI-U traders?

How is it possible for a transaction price to be above the demand curve or below the supply curve?  Is the model wrong?

## THINGS TO TRY

The following suggestions are directly based on and adapted from an exercise distributed by Dr. Robert Axtell (Brookings Institute, Sante Fe Institute, and George Mason University) at the CEEL Summer Workshop on Agent-based Computation Economics held in July 2006.  See http://www-ceel.economia.unitn.it/summer_school/ for information on the CEEL Summer School program.

How well does the model predict?

Determine a setup with the number of buyers and sellers, the maximum buyer value and seller cost, and number of trades.  Conduct several runs of the model.  For each run, note what the predicted competitive equilibrium is by hovering the cursor over the intersection of the supply and demand curves and what the outcomes of the model run was, i.e., average price, standard deviation, market efficiency.  What can you conclude?  Why might the results not perfectly match the predicted competitive equilbirium?  Is there anything about the patterns of trading that improve or impede market efficiency?

[Hint:  you can implement this experiment using the BehaviorSpace wizard available on the tools menu]

Comparative Statics Exercise

Start with an equal number of buyers and sellers and equal values for the maximum buyer value and seller cost.  Run the model several times to get a sense of average price and quantity.  Next double the number of sellers, make several runs, and see what happens to average price and quantity.  Finally half the number of sellers from the original number; again make several runs and note what is happening to average price and quantity.  Repeat the excerise holding the number of sellers at the original value, but double and half the number of buyers.  How well did the model following the predictions of supply and demand theory.

Note that the exercise could be done by holding the number of buyers and sellers constant and varying the maximum buyer value and seller cost.  Also note that the exercise makes the supply and demand curve asymmetric.  Did the asymmetry affect the "ability" of the ZI-C traders to achieve equilibrium?

## EXTENDING THE MODEL

The following suggestions are directly based on and adapted from an exercise distributed by Dr. Robert Axtell (Brookings Institute, Sante Fe Institute, and George Mason University) at the CEEL Summer Workshop on Agent-based Computation Economics held in July 2006.  See http://www-ceel.economia.unitn.it/summer_school/ for information on the CEEL Summer School program.

Change Buyer and Seller Behavior

Implement alternative market rules for how the buyers and sellers form their bid price and ask price.  For example you could implement a ask price formation rule where the sellers ask for as high a price as possible given their potential trading partners.  Or implement a trading mechanism other than an order book such as randomly pair buyers and sellers, forming bid/ask prices, and then trading if the bid and ask cross.  

Given these changes in behavioral rules, does the model a better or worse job of achieving market predictions?  How can that be determined?  Are buyers and sellers better or worse off?  What might happen if the behavioral rule differs for different buyers and for differnt sellers?

Change the scale of the model

Change the scale of the model by changing the maximum number of possible buyers and sellers and the maximum possible number of trading rounds.  Now run progressively larger and larger number of agents.  You may want to run these runs using BehaviorSpace with the screen updating turned off to increase the speed of the runs.

How does the variance in prices change as the population increases? Keep track of the number of ticks of the clock (i.e., interactions) required to equilibrate the market.  Plot the number of interactions as a function of the total number of buyers and sellers.  Does it scale linearly, quadratically, or someother way? Discuss these results in terms of computational complexity.

## REFERENCES

Dhanaanjay K. Gode and Shyam Sunder. 1993.  Allocative Efficiency of Markets with Zero-Intelligence Traders:  Market as a Partial Substitute for Individual Rationality.  The Journal of Political Economy.  101 (Feb. 1993).  119-137.

## COPYRIGHT AND LICENSE

Copyright 2006-2014 

Mark E McBride
Department of Economics  
Miami University  
Oxford, OH 45056  
mark.mcbride@miamioh.edu  
http://memcbride.net/

Last updated:  January 2, 2014

![CC BY-NC-SA 3.0](http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Mark E. McBride at mcbridme@miamioh.edu .
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

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

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
