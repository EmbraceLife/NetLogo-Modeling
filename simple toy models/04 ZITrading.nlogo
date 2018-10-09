;; updated, further explored and heavily commented by 深度碎片
;; code can be downloaded at https://github.com/EmbraceLife/NetLogo-Modeling/blob/master/simple%20toy%20models/04%20ZITrading.nlogo
;; a series of video tutorials accompanies this updated model https://www.youtube.com/playlist?list=PLx08F1efFq_UUB2Mps2f4gauk3YKQtvbY&disable_polymer=true

;; Originally Developed by Mark E. McBride Department of Economics Miami University, Last updated:  January 2, 2014
;; original code and video can be found from https://github.com/memcbride/ZITrading

;; Introduction and usage ;;
;; Gode and Sunder 1993 : Allocative Efficiency Markets with Zero-Intelligent traders: Market as a partial substitute for individual rationality
;; "We report market experiments in which human traders are replaced by 'zero-intelligent' programs that submit random bids and offers.
;; Imposing a budget constraint (i.e., not permitting traders to sell below their costs or buy above their values) is sufficient to raise
;; the allocative efficiency of these auctions close to 100 percent.
;; Allocative efficiency of a double auction derives largely from its structure, independent of traders' motivation, intelligence, or learning."

;; My purpose ;; Why create or study this model on double auction or supply and demand curve?
;; Economics concepts and formulas can be taught differently and explored in more experimentally and realistically or lively
;; see Axtell on Conventional vs [ABM approach to economics](https://youtu.be/YMqq141k_q0?t=1890) up to 53:52

;; presentation ;;
;supply and demand curve
;1. caution : x-axis is not quantity of commodities, but number of price offers
;2. all buy-valuation prices and sell-cost prices are known and laid out in order
;3. buyers and sellers know all their options at once, and highest price buyer has privilege to choose the lowest selling price seller to make a deal.
;3.5 both of they know how to bargain, so they end up the middle price, which seems fair
;4. in reality, no buyer or seller can know all prices available at once, the buyer or trader has to shop around to find the best price available while not losing money or make a profit (limited knowledge and randomness introduced)
;5. a lot of error (variance) introduced, but average price is closer to predicted price, efficiency is high. prove the demand and supply curve is about right.
;6. Interesting Question: why not high price buyers meet high cost seller? and low-buyer with low-seller? why stop in the middle
;- left side trades used up all high price buyers and low price sellers, no high price buyers left for high price sellers (remove-low-price-sellers, protectionsim)
;- high price buyers, while randomly shopping can still find low price sellers, and vice verse. They will look for the best deal within their reach. (remove-high-price-buyers, policy maker set price bars)
;7. if loss is allowed, then many more trades or deals can be made (subsidies to increase economic activities ?)

;; inner workings and rules ;;
;1. each bid, ask and transaction are valid for a single unit
;2. transaction canceled any unaccepted bids and offers
;3. when bid and ask crossed, transaction price was equal to the earlier of the two (in time, who price first)
;4. there are four states of order book
;                               best ask                              best ask                                 ---------   best ask
;---------                     ---------                               ---------                               ---------   ---------
;---------   best ask          ---------        ---------              ---------      ---------                ---------   ---------
;---------   ---------         --------         ---------              ---------      ---------                ---------   ---------
;---------   ---------         ---------        ---------              ---------      ---------                ---------   ---------
;best bid    ---------                          ---------              ---------      ---------                ---------
;           ---------                          best bid               ---------      best bid                 best bid
;
;; 0, value, cost and maxBuyerValue and maxSellerCost
;5. constrained and unconstrained mode
;; rule ;; buyers are randomly assigned buyer values between zero and maxBuyerValue :  buy below value make profit, above value lose money
;; rule ;; Sellers are randomly assigned seller costs between zero and maxSellerCost : sell below cost make lose money, above cost make profit
;; rule ;; In each tick of the clock, either a buyer or seller is randomly selected : randomness introduced
;; rule ;; A buyer randomly forms a bid price between his buyer value and 0 (constrained: no loss), or between maxBuyerValue and 0 (unconstrained: can lose).
;; rule ;; A seller randomly forms an ask price between his seller cost and maxBuyerValue (constrained: no loss) or between 0 and the maxBuyerValue (unconstrained: can lose)
;; rule ;;
   ;; A selected buyer then compares his bid (buy price ) to the current state of the order book (for selling prices )
   ;; If his bid is above the best ask (lowest selling price offered?), he accepts the best ask
   ;; and the buyer and the seller who made the best ask then trade at the best ask. The order book is then emptied.
;; rule ;;
   ;If the buyer’s bid is below the best ask (so there is no best ask for the buyer) and there is no best bid , it becomes the best bid.
   ;; [if buyer's buy price is below the lowest selling price, and there is no highest buy price offered, the buyer's buy price is the highest buy price]
;; rule ;;
   ;;If the buyer’s bid is below the best ask (or there is no best ask) and above the best bid , it replaces the best bid.
   ;;[if buyer's buy price is below the lowest sell price, and above the highest buy price, then the buyer's buy price is the highest ]
;; rule ;;
   ;;If the buyer’s bid is below the best bid, his bid is ignored.
   ;; [if buyer's buy price is below the highest buy price, then his buy price is not the best highest buy price, so no sellers will consider it ]
;; rule ;;
   ;;If the selected seller makes an ask below the best bid, a trade occurs with the best bid at the best bid price.
   ;;[if seller's price is below the highest buy price, the trade is made and the dealPrice is the highest buy price offered]
;; rule ;;
   ;;each buyer and seller can only trade one unit, then they are removed from market
   ;;stop iteration until maxNumberOfTrades is reached.







                                                                                 ;; breeds, properties, globals

breed [buyers buyer]                                                                ;; create breed on [buyers buyer]

breed [sellers seller]                                                              ;; create breed on [sellers seller]

breed [data datum]                                                                  ;; create breed [data datum] to deal with data

buyers-own [value traded? price]                                                    ;; create 3 properties for buyers breed : value, traded? price

sellers-own [cost traded? price]                                                    ;; create 3 properties for sellers breed : cost, traded? price

data-own [Price]                                                                    ;; create a property for data breed : Price (capitalized)

;; globals
globals [transactionPrice                                                           ;; last transaction price

         tickcount                                                                  ;; number of times simulation has run

         maxSurplus                                                                 ;; maximum surplus possible from market

         actualSurplus                                                              ;; surplus extracted by trades

         efficiency                                                                 ;; efficacy is how close is actualSurplus approach to maxSurplus

         traders                                                                    ;; agentset of all buyers and sellers

         bestBid                                                                    ;; current best Bid

         bestBidID                                                                  ;; buyer with current best bid

         bid?                                                                       ;; bid available?

         bestAsk                                                                    ;; current best Ask

         bestAskID                                                                  ;; seller with current bestAsk (providing the lowest selling price)

         ask?                                                                       ;; ask available?

         predictedq                                                                 ;; predicted market q (accumulated number of transaction of ideal situation)

         predictedp                                                                 ;; predicted market p (mean of buyer's value and seller's cost on ideal situations)

        ]


to setup                                                                         ;; Build the world

  clear-all                                                                         ;; clear out all previous variables

    ask n-of numberOfBuyers patches [                                               ;; ask each and every certain numbers of patches to (randomly distributed)

      sprout-buyers 1 [init-buyer]                                                     ;; born a buyer and initialize it

      ]

    ask n-of numberOfSellers patches [                                              ;; ask each and every certain numbers of patches to (randomly distributed)

      sprout-sellers 1 [init-seller]                                                   ;; born a seller and initialize it

      ]

    calc-max-surplus                                                                ;; calculate the max surplus in this market

    set actualSurplus 0.0                                                           ;; initialize actual surplus

    init-orderBook                                                                  ;; initialize the orderbook

    set traders turtles with [breed = buyers or breed = sellers]                    ;; create traders agentset


    reset-ticks                                                                     ;; put clock to 0

  create-demand-supply                                                              ;; draw supply curve (all sellers' cost points), demand curve (all value points)
  end

;; restore the default parameters
to restore-defaults
    set numberOfBuyers 50
    set numberOfSellers 50
    set maxNumberOfTrades 2000
    set maxBuyerValue 200.0
    set maxSellerCost 200.0
    set constrained? true
    set remove-low-cost? false
    set remove-high-buyer? false
    ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  clear-all
  reset-ticks
  end


to go                                                                           ;; main loop

  if ticks = maxNumberOfTrades [                                                ;; end the simulation?

    draw-histogram-prices

    stop
  ]

    doTrade                                                                     ;; make transactions

    tick
  end


to init-buyer                                                                    ;; initialize buyer

    set color black                                                                 ;; use color black to hide itself

    set value random-float maxBuyerValue                                            ;; set a random buying value between 0 and maxBuyerValue

    set traded? false                                                               ;; set trade-mode off
    ;; print out the buyer information
    ;; show value
  end


to init-seller                                                                   ;; initialize seller

    set color black                                                                 ;; use color black to hide itself

    set cost random-float maxSellerCost                                             ;; set a random cost between 0 and maxSellerCost

    set traded? false                                                               ;; set trade-mode off
    ;; print out the seller information
    ;; show cost
  end


to init-orderBook                                                                ;; initialize the orderBook

    set bestBid 0.0                                                                 ;; set highest bid or buy price (for seller)  0 [can't be lower, no deal]

    set bestBidID nobody                                                            ;; set best bider ID to be nobody

    set bid? false                                                                  ;; set global bid-mode off

    set bestAsk maxSellerCost                                                       ;; set lowest ask price (for buyer) to be maxSellerCost [can't be higher, no deal]

    set bestAskID nobody                                                            ;; set best asker ID to be nobody

    set ask? false                                                                  ;; set global ask-mode off

  end



to-report formBidPrice                                                            ;; ZI-C buyer, has two ways to form a bidprice

  ifelse constrained?                                                                 ;; if buyers are constrained?

    [ report value - (random-float 1) * (value - 1) ]                                ;; ZI-C:  buyers will not bid above their buyer value ( randomness introduced )

    [ report (random-float 1) * (maxBuyerValue - 1) ]                                ;; ZI-U:  buyers will bid up to maxBuyerValue (randomness introduced)

  end


to-report formAskPrice                                                            ;; ZI-C seller, has two ways to form a askPrice

  ;; if cost > maxBuyerValue [show "seller has cost =" + cost  + "> maxBuyerValue"]
  ifelse constrained?                                                                 ;; if sellers are constrained?

    [ report cost + (random-float 1) * abs ((maxBuyerValue - cost)) ]                 ;; sellers will not sell below their seller cost  ( randomness introduced )

    [ report (random-float 1) * (maxSellerCost - 1) ]                                 ;; sellers may ask below their seller cost (randomness introduced)
  end


to doTrade                                                                         ;; identify potential traders and see if they'll trade

  let bidID 0                                                                      ;; who bid
  let bidPrice 0                                                                   ;; bid-price
  let askID 0                                                                      ;; who sell
  let askPrice 0                                                                   ;; sell-price
  let transPrice 0                                                                 ;; transaction price
  let tradeID 0                                                                    ;; which trade


    set transPrice 0.0                                                             ;; set transPrice 0.0

    set tradeID one-of traders with [traded? = false]                              ;; randomly select a buyer or seller who has not traded yet
                                                                                   ;; so far all traders are not yet made any deals (trade-mode off in setup)


    if remove-low-cost? [

       let expensive-sellers sellers with [ cost > maxSellerCost / 2 ]
       set traders turtles with [breed = buyers or member? self expensive-sellers]
       set tradeID one-of traders with [traded? = false  ]
    ]

    if remove-high-buyer? [

       let low-price-buyers buyers with [ value < maxBuyerValue / 2 ]
       set traders turtles with [breed = sellers or member? self low-price-buyers ]
       set tradeID one-of traders with [traded? = false  ]
  ]

    if tradeID = nobody [ stop ]                                                   ;; stop if there was nobody left to trade

    if exp-options = "do trade once" [ show ( word "this trader belongs to " [breed] of tradeID ) ]

    ask tradeID [                                                                  ;; ask the trader
      ifelse breed = buyers                                                        ;;  if trader is a buyer

        [
          set bidPrice [formBidPrice] of tradeID                                   ;; get buyer's price based on its value and maxBuyerValue according constrained?

          if exp-options = "do trade once" [

             show ( word "this buyer set value at " round value ", set maxBuyValue at " maxBuyerValue
                    ", constrained? by value : " constrained? ", bidPrice is at " precision bidPrice 2 )

             show "Let's check the current orderbook states : "
             show (word "ask? mode is " ask? ", bid? mode is " bid?  ", bestAsk : " precision bestAsk 2 ", bestBid : " precision bestBid 2 ", bestBidID : " bestBidID ", bestAskID : " bestAskID)
          ]

          ifelse ask? and (bidPrice > bestAsk)                                     ;; if somebody is selling and buyPrice > the lowest selling price (for buyers) at maxSellerCost

            [
              set transPrice bestAsk                                               ;; accept the `bestAsk` (lowest selling price) to be the global `transPrice` (by buyer)

              ask tradeID [set traded? true                                        ;; update buyer's traded-mode true (the deal is done, trade is done)

                           set price transPrice]                                   ;; and update buyer's price to be `transPrice`


              ask bestAskID [                                                      ;; ask the seller with the lowest selling price

                  set traded? true                                                    ;; update seller's traded-mode true

                  set price transPrice]                                               ;; set price to be transPrice


              set transactionPrice transPrice                                      ;; pass transaction price from local var `transPrice` to global var `transactionPrice`

              set actualSurplus (actualSurplus + [value] of tradeID - [cost] of bestAskID)  ;; calc global actualSurplus =
                                                                                   ;;  = actualSurplus + buyer's value - the cost of the seller with lowest selling prices (costs)

              set efficiency (actualSurplus / maxSurplus) * 100                    ;; efficacy is how close is actualSurplus approach to maxSurplus

              if exp-options = "do trade once" [
                 show (word "if selling mode is on, and buyPrice > the lowest selling price (for buyers), meaning the buyer can make a deal. ")
                 show (word " the buyer pick the bestAsk (lowest selling price) to be transaction price: " precision bestAsk 2 ", buyPrice is " precision bidPrice 2)
                 show (word " set the buyer's traded? mode to be true and set its price to be transaction price. ")
                 show (word " the seller with lowest selling price, will set traded? mode true and set its price to be transaction price. ")
                 show (word " transaction price is saved in transactionPrice to plot below" )
                 show (word " actualSurplus is accumulated at each transaction with (value of buyer - cost of seller). The diff is " ([value] of tradeID - [cost] of bestAskID) )
                 show (word " efficacy is how close is actualSurplus approach to maxSurplus so far:  " efficiency )

              ]

             set-current-plot "demand-supply"
             set-current-plot-pen "trade-cost"
             plot [cost] of bestAskID
             set-current-plot-pen "trade-value"
             plot [value] of tradeID

            ]

                                                                                ;; when ask-mode is off or buy price is lower or equal to lowest selling price
                                                                                ;; meaning no buy deal is possible
            [
              ifelse bidPrice > bestBid                                                 ;; if buyer's price > bestBid (the highest buying price for seller)
              [
                set bid? true                                                       ;; set the bid-mode? true

                let previous-bestBid bestBid

                set bestBid bidPrice                                                ;; set the bidPrice becomes bestBid (the highest buying price for sellers)

                set bestBidID tradeID                                               ;; set bestBidId to be traderID

                if exp-options = "do trade once" [
                   show (word "when ask-mode is off or buy price is lower or equal to lowest selling price, meaning no deal is possible. ")
                   show (word " if buyer's price > bestBid (the highest buying price for seller) : " precision bidPrice 2 " > " precision previous-bestBid 2 )
                   show (word " get global bid? mode on. Since bidPrice is higher than bestBid, make it bestBid. ")
                   show (word " now all the globals are the following : ")
                   show (word "ask? mode is " ask? ", bid? mode is " bid?  ", bestAsk : " precision bestAsk 2", bestBid : " precision bestBid 2 ", bestBidID : " bestBidID ", bestAskID : " bestAskID)
                ]
              ]
              [
                 if exp-options = "do trade once" [
                    show (word " since bidPrice (buying price) : " precision bidPrice 2 " <= bestBid (highest buying price) " precision bestBid 2 )
                    show (word " the buyer's buying price is not high enough to stand out to attract sellers. Only the bestBid, the highest buying price can deal.")
                 ]
              ]



            ]
        ]
                                                                                  ;; otherwise, meaning when the trader is a seller
        [
          set askPrice [formAskPrice] of tradeID                                     ;; get ask price for this seller based on its cost, constrained? by maxSellerCost or not

          if exp-options = "do trade once" [

             show ( word "this seller set cost at " round cost ", set maxSellerCost at " maxSellerCost
                    ", constrained? by cost : " constrained? ", askPrice is at " precision askPrice 2 )

             show "Let's check the current orderbook states : "
             show (word "ask? mode is " ask? ", bid? mode is " bid?  ", bestAsk : " precision bestAsk 2 ", bestBid : " precision bestBid 2 ", bestBidID : " bestBidID ", bestAskID : " bestAskID)
          ]

          if (askPrice < cost) and (constrained?)                                     ;; if sell price is below cost, and sell price can't be less than cost

            [ show "if sell price is below cost, and sell price can't be less than cost due to constraints"
            ]

          ifelse bid? and (bestBid > askPrice)                                        ;; if selling mode is on and highest buy price is above selling price

            [
              set transPrice bestBid                                                  ;; seller will take the highest buy price to be transPrice

              ask bestBidID [set traded? true                                         ;; ask the highest price buyer to set traded? true

                             set price transPrice]                                    ;; set its price to be transPrice

              ask tradeID [set traded? true                                           ;; ask the seller to set traded? true

                           set price transPrice]                                      ;; set the seller's price to transPrice

              set transactionPrice transPrice                                         ;; update the transPrice to transactionPrice

              set actualSurplus (actualSurplus + [value] of bestBidID - [cost] of tradeID)
                                                                                      ;; update actualSurplus = self + transactionPrice - seller's cost (profit by seller)

              set efficiency (actualSurplus / maxSurplus) * 100                       ;; update efficiency with the latest and added up actualSurplus


              if exp-options = "do trade once" [
                 show (word "if buying mode is on, and sellPrice < the highest buy price (for sellers), meaning the seller can make a deal. ")
                 show (word " the sell pick the bestBid (highest buying price) to be transaction price: " precision bestBid 2 ", sellPrice is " precision askPrice 2)
                 show (word " set the seller's traded? mode to be true and set its price to be transaction price. ")
                 show (word " the seller with lowest selling price, will set traded? mode true and set its price to be transaction price. ")
                 show (word " transaction price is saved in transactionPrice to plot below" )
                 show (word " actualSurplus is accumulated at each transaction with (value of buyer - cost of seller). The diff is " ([value] of bestBidID - [cost] of tradeID) )
                 show (word " efficacy is how close is actualSurplus approach to maxSurplus so far:  " efficiency )

              ]


             set-current-plot "demand-supply"
             set-current-plot-pen "trade-cost"
             plot [cost] of tradeID
             set-current-plot-pen "trade-value"
             plot [value] of bestBidID


            ]

            [                                                                         ;; if selling mode is off or highest buy price is less selling price
                                                                                      ;; meaning no selling deal can be made

              ifelse askPrice < bestAsk                                                   ;; if selling price is below the lowest selling price
              [
                set ask? true                                                         ;; now set global selling-mode on, ready to make a sell deal (now) next time

                let previous-bestAsk bestAsk

                set bestAsk askPrice                                                  ;; make the current sell price to be the lowest selling price `bestAsk`

                set bestAskID tradeID                                                 ;; make the current seller to lowest selling price seller

                if exp-options = "do trade once" [
                   show (word "if selling mode is off or the highest buy price : " precision bestBid 2 " is less selling price : " precision askPrice 2  ", meaning no selling deal can be made.")
                   show (word " make sure turn sell-mode on and ready to sell now.")
                   show (word "if selling price : " precision askPrice 2 " is below the lowest selling price : " precision previous-bestAsk 2 " , make selling price to be the bestAsk" )
                   show (word " make the seller to be bestAskID " tradeID )
                   show "Let's check the current orderbook states again : "
                   show (word "ask? mode is " ask? ", bid? mode is " bid?  ", bestAsk : " precision bestAsk 2", bestBid : " precision bestBid 2 ", bestBidID : " bestBidID ", bestAskID : " bestAskID)
                ]
              ]
              [
                 if exp-options = "do trade once" [
                    show (word " since askPrice (selling price) : " precision askPrice 2 " >= bestAsk (lowest selling price) " precision bestAsk 2 )
                    show (word " the seller's selling price is not low enough to stand out to attract buyers. Only the bestAsk, the lowest selling price can deal.")
                 ]
              ]

            ]
        ]
    ]

    if transPrice > 0.0                                                               ;; as long as a transaction is made

      [ create-data 1 [set price transPrice]                                          ;; create a trade data on it, save its transPrice in price

        draw-transaction                                                              ;; plot this transaction price of this deal

        init-orderBook                                                                ;; initialize orderbook again for next trade

        if exp-options = "do trade once" [
           show (word "a deal is done at " precision transPrice 2 ", now create a data and plot the transaction price, and initialize orderbook for next trade. ")
           show (word " all transaction prices are saved into data, in the end all data prices together become histogram plot)")
        ]
      ]
  end

                                                                                   ;; calculate the maximum possible surplus from market
                                                                                   ;; and calculate predicted equilibrium
to calc-max-surplus

  let bids 0                                                                       ;; initialize local vars bids, asks, as list containers
  let asks 0
  let surpluses 0

  set surpluses 0.0                                                                ;; set surpluses 0.0 float number

;    set bids sort-by [ [?1 ?2] -> ?1 > ?2 ] [value] of buyers
  set bids sort-by [ [value1 value2] -> value1 > value2 ] [value] of buyers        ;; sort buyers by value from big to small
;    set bids sort-by > [value] of buyers

;  set asks sort-by [ [?1 ?2] -> ?1 < ?2 ] [cost] of sellers
  set asks sort-by <  [cost] of sellers                                            ;; sort sellers by cost from small to big


  if exp-options = "setup" [                                                       ;; tell the story of setup

    show "buyers and sellers are initialized with different values and costs."
    show (word "There are " (length bids) " buyers. Their values for commodities are ranging from large to small. ")
    show word "all bids: " bids
    ;  foreach bids [ x -> show word "bid=" x]  ;; to print on columns
    show (word "There are " length asks " sellers. Their costs for commodities are ranging from small to large.")
    show (word "all asks: " asks)
    ;  user-message(word "to make sure the number of minority traders are matched by the other side")
    show "Now, to make sure the number of majority group are matched by the minority group"
  ]
    if (numberOfBuyers != numberOfSellers) [                                       ;; if numberOfBuyers != numberOfSellers

      ifelse (numberOfBuyers < numberOfSellers)                                    ;; if numberOfBuyers < numberOfSellers (make sure smaller number of traders matched)

        [ set asks sublist asks 0 (numberOfBuyers) ]                                  ;; make sure asks has numberOfBuyers items (make sure matched)

        [ set bids sublist bids 0 (numberOfSellers) ]                                 ;; otherwise, make sure bids has numberOfSellers items (of course)

      ]

  if exp-options = "setup" [
    show word "total-bids: " length bids
    show word "total-asks: " length asks
    ;  user-message(word "Now, they are matched. ")
    show "Now, they are matched. All deals added up into Predictedq and each deal's mean price is assigned to Predictedp"
  ]

    set predictedq 0                                                                  ;; cross-point quantity for the two curves

    set predictedp 200                                                                ;; cross-point price for the two curves (200 ? here = [199 + 200] / 2 )
                                                                                      ;; it can be any number



     if exp-options = "setup" [

        show "If Buyer's value is above Seller's cost, seller makes profit, buyers take no loss, Deal!."
        show "If buyer's value price is below Seller's cost, seller won't sell below its cost, buyer won't buy it above its value. No deal!"
        show "Let's calculate how much profit or surplus can be made : "
      ]

;    (foreach bids asks [ [?1 ?2] -> if ( ?1 - ?2 > 0.0) [
    (foreach bids asks [ [bid1 ask1] ->                                               ;; pair bids (from high to low) with asks (from low to high), and loop each pair

      if (bid1 - ask1 > 0.0 )[                                                             ;; only when buy price > sell price, a deal is made
         set predictedq predictedq + 1                                                      ;; one deal is done, add 1 to predictedq

   ;     set predictedp (?1 + ?2) / 2
         set predictedp (bid1 + ask1) / 2                                                   ;; predicted price is lower than value and higher than cost, both buyer and sellers can profit

;        set surpluses (surpluses + ?1 - ?2) ]
         set surpluses (surpluses + bid1 - ask1)                                            ;; update surpluses by adding up the sold profit = (bid1-ask1)

         set-current-plot "demand-supply"
         set-current-plot-pen "predicted-price"
         plot predictedp

       ]


       if exp-options = "setup" [


          show (word "bid = " round bid1 " ask = " round ask1 )
          ifelse bid1 > ask1 [show "Deal!"] [show "No deal!"]
          show (word " surplus = surplus + bid - ask = " round surpluses " q= " predictedq " p= " round predictedp)

         ]
      ]
     )

     set maxSurplus surpluses                                                         ;; all trades' surpluses = maxSurplus = all trades' sold profit

  end


to create-Demand-Supply                                                               ;; draws the demand-supply curves for the values

    set-current-plot "Demand-Supply"                                                  ;; set plot

    set-current-plot-pen "demand-value"                                                 ;; set pen

;    foreach sort-by [ [?1 ?2] -> [value] of ?1 > [value] of ?2 ] buyers
    foreach sort-by [ [buyer1 buyer2] -> [value] of buyer1 > [value] of buyer2 ] buyers  ;; sort buyers from big value to small value, and for each buyer to do

      [ x -> plot [value] of x ]                                                      ;; plot this buyer's value (all buyers' values forms the line)

    set-current-plot-pen "supply-cost"                                                 ;; set pen to draw supply curve

    foreach sort-by [ [seller1 seller2] -> [cost] of seller1 < [cost] of seller2 ] sellers  ;; sort sellers from small value to big value, and for each seller to do

      [ x -> plot [cost] of x ]                                                       ;; plot this seller's cost (all sellers' costs forms the line)
  end


to draw-transaction                                                                   ;; draws the transactions on the demand-supply curves

    set-current-plot "Demand-Supply"

    set-current-plot-pen "real-transPrice"

    plot transactionPrice
  end


to draw-histogram-prices                                                               ;; draws the histogram of the transaction prices

    set-current-plot "Price Dispersion"

    histogram [price] of data
  end


;; Developed by:
;; Mark E. McBride
;; Department of Economics
;; Miami University
;; Oxford, OH 45056
;; mark.mcbride@miamioh.edu
;; http://memcbride.net/
;; http://www.memcbride.net/labs/
;; Last updated:  January 2, 2014
;; code and a video can be found from https://github.com/memcbride/ZITrading

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
;;  Added a constrained? switch to implement either ZI-C or ZI-U
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
1217
10
1427
221
-1
-1
3.961
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
50
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
50.0
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
200.0
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
435
109
501
142
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
684
105
749
138
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
11
197
935
618
Demand-Supply
Quantity (price offers)
Price (cost or value or transprice)
0.0
40.0
0.0
40.0
true
true
"" ""
PENS
"supply-cost" 1.0 0 -2674135 true "" ""
"demand-value" 1.0 0 -13345367 true "" ""
"real-transprice" 1.0 0 -16777216 true "" ""
"predicted-price" 1.0 0 -4699768 true "" ""
"trade-cost" 1.0 0 -955883 true "" ""
"trade-value" 1.0 0 -13840069 true "" ""

BUTTON
376
42
441
75
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
962
536
1021
581
Volume
count data
0
1
11

MONITOR
1019
536
1090
581
Avg Price
mean [price] of data
2
1
11

MONITOR
1089
536
1148
581
Std Dev
standard-deviation [price] of data
2
1
11

PLOT
962
362
1176
525
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
973
114
1169
278
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
1147
536
1208
581
Efficiency
efficiency
2
1
11

SWITCH
456
44
592
77
constrained?
constrained?
0
1
-1000

MONITOR
1052
291
1110
336
Pred. Q
predictedq
0
1
11

MONITOR
1110
291
1167
336
Pred. P
predictedp
2
1
11

CHOOSER
20
15
112
60
exp-options
exp-options
"none" "setup" "do trade once"
2

SWITCH
641
27
821
60
remove-low-cost?
remove-low-cost?
1
1
-1000

SWITCH
642
66
828
99
remove-high-buyer?
remove-high-buyer?
0
1
-1000

BUTTON
560
107
623
140
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
