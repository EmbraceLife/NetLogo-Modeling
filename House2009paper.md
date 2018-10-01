# An Agent-Based Model of the English Housing Market

[original paper and model](http://cress.soc.surrey.ac.uk/housingmarket/ukhm.html) 

## Abstract

> Uniqueness of UK house market 
>
> - Stock of houses is fixed in short term
> - buyers need finance to buy houses 
> - prices are set by realtors 
>
> Why ABM
>
> - to explore the emergence features out of interactions between multiple agents 

## The Housing Market

> Conventional approach 
>
> - top down, econometric model 
> - use interest rate, income, supply and demand of houses 
> - to estimate price projection 
>
> drawbacks of conventional approach 
>
> - know little of underlying mechanism of housing market 
>
> potential advantages of using ABM 
>
> - to model **locations**, which is critical to prices at micro-level 
> - to incorporate **realtors**, who set the price, as a different agent to households, 
> - to explain better the house price to earning ratio **over time** 
>
> Uniqueness to previous researches 
>
> - incorporate realtors 
> - don't model buyer or seller utility nor assume utility maximization
>   - this paper, all buyers assume high price equal to high quality 
>
> Simulating complex patterns of housing market 
>
> - to replicate real world housing market key features 
> - phenomena 1 : sticky downward 
>
>   - demand increase, price rise in short term, price stable and fall as more houses are into the market 
>   - demand decrease, price will be stable in short term, but in long run it will fall 
>   - we can use this phenomena to **verify** our model and it seems our model can simulate such pattern see verification video [CN](https://youtu.be/srThVXLdxU0?list=PLx08F1efFq_WYCEUW9hDv_kfH3LmJs3TL) and [EN](https://youtu.be/n1NY5Flx9o8?list=PLx08F1efFq_XPiMl74IHpppb8NGqITLn2) 
> - phenomena 2 : interest rise cause house price to fall 
>   - see verficiation video [CN](https://www.bilibili.com/video/av31860025/?p=41) and [EN](https://youtu.be/HebhzFXYqkw?list=PLx08F1efFq_XPiMl74IHpppb8NGqITLn2)  
>
> Model on locality 
>
> - no attempt to represent either the characteristics of individual housing units
> - nor spatial attributes such as proximity to facilities
> - differentiated only by a neighbourhood index (local houses prices)

## The model 

> The households 
>
> - have income, mortgage, capital, deposit, repayment
>   - `income` with gamma distribution with parameters at 1.3 and $5\times10^{-5}$ with `MeanIncome` 
>   - `mortgage` is determined by `income, Affordability, InterestRate`
>   - initial house purchase is done by mortgage with 25 years duration
>   - deposit is determined by `MaxLoanToValue` 
>   - every tick `Shocked` % households, half have 20% income rise, the other half 20% drop
> - exit when death or job relocation (forced exit the area )
>   - `ExitRate`
> - exit when mortgage is too expensive for income (forced exit the area ) 
> - every tick `EntryRate` % of population come into the city, look for houses to buy
> - as new comers exit when discouraged due to being homeless too long `MaxHomelessPeriod`
> - move when they try to trade down, when  `income` is less than half `Affordability`
> - move when they try to trade up, when `income` is more than twice `Affordability`
> - sell house with the highest valuation provided by realtors 
> - make an offer on the most expensive but affordable house on sale (the first get the deal)
> - make the deal and move into the new house if sale chain is intact 
> - If the sale price is insufficient to pay off the mortgage, the seller is in a position of ‘negative equity’ and has to withdraw the house from the market.
>
> The houses
>
> - has its sale-price, quality, on-sale or not, my-owner, my-realtor, local-realtors
> - have their initial `sale-price` based on owners `mortgage` and `deposit` (not for sale at very beginning)
> - have their `local-realtors` based on locality 
> - set `for-sale? true` due to householders have income shock, set `date-for-sale`
> - having the highest valuation as `sale-price` (updated) and the realtor as `my-realtor`
> - track the buyer who made an offer as `offered-to`, set `offer-date` 
> - houses too old (`end-of-life` calc with `HouseMeanLifeTime`) or too cheap are demolished 
> - a certain number of new houses are born into the city every tick
> - if `follow-chain` is intact, deal is made, change `my-owner`, set `for-sale? false`, 
> - if not sold this tick, reduce its `sale-price` by certain ratio for next tick,
> - If an offer fails to go through in one period, it immediately lapses.
> - create new `HouseConstructionRate` per cent houses of the existing housing stock, unless there are no empty plots.
>
> The Realtors
>
> - has `my-houses` to its territory, calc their `averaging-price`
> - provide valuation to houses based on locality (3 types of localness)
> - keep records of sold houses in `sales` list 
> - update sales list (of records) and my-houses
>   - remove demolished houses from my houses
>   - remove demolished houses records from sales list 
>   - if records are too old without update (cos no deal), remove them, and update the houses prices with new record 
>
> The Records
>
> - create records of houses are just sold (at the start and at every tick)
> - if the record house is sold again, a new record will be created, the old record should be removed at some point? 
> - if the record house is demolished, the record should be removed as well at some point ? 
>
>

# Coding Tasks

follow an owner's life story : follow-me, inspect, and type in console 

follow a house's life story

follow a record's life story 

follow a realtor's life story

# Code Problems 

## Drop owner numbers

### Problem Description

> within 100 ticks number of owners halfed
>
> nDiscouraged and nForceOut continued to rise, nDiscouraged is the larger part
>
> no matter how interest rate change, income-shock change, the above situation does not change 
>
> ==is it normal? or is the coding wrong somewhere?== 

### Approach 1

> nDiscouraged is due to long time being homeless, not able to buy a house 
>
> nForceOut is due to repayment is greater than income 
>
> so, I suspect the problem lies at the buying and valuation processes 
>
> [Inspection strategy](https://github.com/EmbraceLife/shendusuipian/blob/8aec0a6fa95307dfeeaf664218426cb3ce28099b/complexity_demos/Housing%20market%20in%20process#L693) to look for the cause of the problem

### Reflection 1

> Inspection on the entire system is difficult, as it is too complex and interactive. 
>
> ==Inspect thoroughly each part during code construction== 