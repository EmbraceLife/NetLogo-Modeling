[Big Debt Crisis.pdf](Big Debt Crisis.pdf)

## What is goodness or badness of debt

```
goodness-badness = what credit produces or how the debt is repaid
```

> Clearly, giving the ability to make purchases by providing credit is, in and of itself, a good thing, and not providing the power to buy and do good things can be a bad thing. the question of whether rapid credit/ debt growth is a good or bad thing hinges on what that credit produces and how the debt is repaid (i.e., how the debt is serviced).

## No debt can be as bad as Too much bad debt

```
badness-no-debt = value-losing-opportunities = value-too-much-bad-debt
```

> too little credit/debt growth can create as bad or worse economic problems as having too much, with the costs coming in the form of foregone opportunities.

## How to measure whether a debt is good or not 

```
if productivity-on-credit > threshold [ 
   set sufficient-income-service-debt? true
   set debt good-debt]
```

> Generally speaking, because credit creates both spending power and debt, whether or not more credit is desirable depends on whether the borrowed money is used productively enough to generate sufficient income to service the debt.

## When is subway debt good or bad?

```
;; In what scenario, is subway debt a good one?
let repayment-25y subway-revenue * (1 + revenue-growth-rate) ^ 25 - yearly-cost * (1+inflation-rate) ^ 25 + (social-economic-benefit-25y - gov-subsidies-25y)
if debt - repayment-near > 0 and repayment-25y > debt * 1.02 ^ 25  [ set debt good-debt ] 
```

> Suppose that you, as a policy maker, choose to build a subway system that costs $1 billion. You finance it with debt that you expect to be paid back from revenue, but the economics turn out to be so much worse than you expected that only half of the expected revenues come in. The debt has to be written down by 50 percent. Does that mean you shouldn’t have built the subway? 
>
> Rephrased, the question is whether the subway system is worth $500 million more than what was initially budgeted, or, on an annual basis, whether it is worth about 2 percent more per year than budgeted, supposing the subway system has a 25-year lifespan. Looked at this way, you may well assess that having the subway system at that cost is a lot better than not having the subway system. 

```
;; In what scenario, is subway debt a really bad one?
let repayment-25y subway-revenue * (1 + revenue-growth-rate) ^ 25 - yearly-cost * (1+inflation-rate) ^ 25 + (social-economic-benefit-25y - gov-subsidies-25y)
if debt - repayment-near > 0 and repayment-25y < 0  [ set debt really-bad-debt ] 

;; what is the ratio of really-bad-debt to GDP ?
to-report bad-debt-to-gdp write-down-ratio bad-debt-total-debt-ratio
   let bad-debt-value total-debt-value * bad-debt-total-debt-ratio
   let bad-debt-write-down bad-debt-value * write-down-ratio
   let GDP total-debt-value / 2
   report bad-debt-write-down / GDP
end 

;; if bad debt is 20% of total debt, which has to lose 40% of value, total-debt is twice GDP
let gdp-drop bad-debt-to-gdp 40% 20% ;; then value to lose is equal to 16% GDP

;; to drop 16% of GDP within a year, is not tolerable; but drop 1% of GDP per year for 16 years, is tolerable. But whether policy maker will spread loss depend on two factors 
ask really-bad-debt [
  if debt-currency-control > threshold and influence-over-creditor-debtor > threshold [ set tolerable true ]
  ]
```

> downside risks of having a significant amount of debt depends a lot on the willingness and the ability of policy makers to spread out the losses arising from bad debts. I have seen this in all the cases I have lived through and studied. Whether policy makers can do this depends on two factors: 1) whether the debt is denominated in the currency that they control and 2) whether they have influence over how creditors and debtors behave with each other.

## Are Debt cycles inevitable ?

```
;; Debt cycles are inevitable ?
if human-short-sightedness > threshold1 and political-short-sightedness > threshold2 [ set credit-loose true]
;; maybe 95% time human and political short-sightedness is greater than the thresholds
;; how to model human-short-sightedness and political-short-sightedness?
```

> Throughout history only a few well-disciplined countries have avoided debt crises. While policy makers generally try to get it right, more often than not they err on the side of being too loose with credit because the near-term rewards (faster growth) seem to justify it. It is also politically easier to allow easy credit (e.g., by providing guarantees, easing monetary policies) than to have tight credit. That is the main reason we see big debt cycles.

## Why do debt crises come in cycles?

```
set total-debt = borrowed + borrowed * interest-rate
if asset-value-on-borrowed * profit-growth > borrowed * interest-rate [ set debt-sustainable true]
if income < cost-of-loans [ set debt-sustainable false]
```

> You’re not just borrowing from your lender; you are borrowing from your future self. Essentially, you are creating a time in the future in which you will need to spend less than you make so you can pay it back. <u>The pattern of borrowing, spending more than you make, and then having to spend less than you make very quickly resembles a cycle.</u> This is as true for a national economy as it is for an individual. Borrowing money sets a mechanical, predictable series of events into motion.
>
> <u>Lending naturally creates self-reinforcing upward movements that eventually reverse to create self-reinforcing downward movements that must reverse in turn. During the upswings, lending supports spending and investment, which in turn supports incomes and asset prices; increased incomes and asset prices support further borrowing and spending on goods and financial assets. The borrowing essentially lifts spending and incomes above the consistent productivity growth of the economy. Near the peak of the upward cycle, lending is based on the expectation that the above-trend growth will continue indefinitely. But, of course, that can’t happen; eventually income will fall below the cost of the loans.</u>

```
households-payments = land-cost + realtor-cost + construction-cost = gov-income + realtor-income + workers-business-income = borrowing + interest + profit-or-income
if profit-income > borrowing-interest [ set housing-debt-sustainable? true] [set ...? false]
housing-project = finite-short-term-business = no long-term-growth after built
if not housing-debt-sustainable? [
	set asset-price high  
	set wages high  
	set debt-interest-rate high
	set income-now-future lower
	set economic-growht-drive-low? true]
```

> Economies whose growth is significantly supported by debt-financed building of fixed investments, real estate, and infrastructure are particularly susceptible to large cyclical swings because the fast rates of building those long-lived assets are not sustainable. If you need better housing and you build it, the incremental need to build more housing naturally declines. As spending on housing slows down, so does housing’s impact on growth. Let’s say you have been spending 10 million a year to build an office building (hiring workers, buying steel and concrete, etc.). When the building is finished, the spending will fall to $0 per year, as will the demand for workers and construction materials. From that point forward, <u>growth, income, and the ability to service debt will depend on other demand.</u> This type of cycle—where a strong growth upswing driven by debt-financed real estate, fixed investment, and infrastructure spending is followed by a downswing driven by a debt-challenged slowdown in demand—is very typical of emerging economies because they have so much building to do.

```
if new-borrowing-repay-old-interest? [ set strong-warning-signal? true ]
```

> In “bubbles,” the unrealistic expectations and reckless lending results in a critical mass of bad loans. At one stage or another, this becomes apparent to bankers and central bankers and the bubble begins to deflate. One classic warning sign that a bubble is coming is when an increasing amount of money is being borrowed to make debt service payments, which of course compounds the borrowers’ indebtedness.

```
if monetary-policy-tighten? and debt-cost > new-borrowing [ 
   set new-lending-slow? true
   set service-debt-hard? true
   set spending-investment-slow? true
   set income-growth-slow? true
   ]
```

> When money and credit growth are curtailed and/or higher lending standards are imposed, the rates of credit growth and spending slow and more debt service problems emerge. At this point, the top of the upward phase of the debt cycle is at hand. Realizing that credit growth is dangerously fast, the central banks tighten monetary policy to contain it, which often accelerates the decline (though it would have happened anyway, just a bit later). In either case, when the costs of debt service become greater than the amount that can be borrowed to finance spending, the upward cycle reverses. Not only does new lending slow down, but the pressure on debtors to make their payments is increased. The clearer it becomes that debtors are struggling, the less new lending there is. The slowdown in spending and investment that results slows down income growth even further, and asset prices decline.

```
set critical-parties lending-institutions-highest-leverage
set priority-tactic contain-collapse-of-critical-parties
set new-criticial-parties [insurance companies, non-bank trusts, broker-dealers, and even special purpose vehicles]
```

> When borrowers cannot meet their debt service obligations to lending institutions, those lending institutions cannot meet their obligations to their own creditors. Policy makers must handle this by dealing with the lending institutions first. The most extreme pressures are typically experienced by the lenders that are the most highly leveraged and that have the most concentrated exposures to failed borrowers. These lenders pose the biggest risks of creating knock-on effects for credit worthy buyers and across the economy. Typically, they are banks, but as credit systems have grown more dynamic, a broader set of lenders has emerged, such as insurance companies, non-bank trusts, broker-dealers, and even special purpose vehicles.

## Can Most Debt Crises Be Managed so There Aren’t Big Problems?

```
if debt-own-currency? and debt-spread-out? [ set debt-tolerable? true ]
if policy-makers-ignorant? or politically-harm-others-process? [ set likely-big-problem? true]
```

> I believe that it is possible for policy makers to manage them well in almost every case that the debts are denominated in a country’s own currency. That is because the flexibility that policy makers have allows them to spread out the harmful consequences in such ways that big debt problems aren’t really big problems.
>
> but the biggest risks are not from the debts themselves but from a) the failure of policy makers to do the right things, due to a lack of knowledge and/or lack of authority, and b) the political consequences of making adjustments that hurt some people in the process of helping others.

```
set difficulties-debt-crises [ debt-in-foreign-currency  some-people-hurt-greatly ]
set how-handle-debt-crises-well [ know-how-to-use-levers-well  have-authority  know-spread-out-rate  know-who-benefit-suffer  ]
```

> I want to reiterate that 1) when debts are denominated in foreign currencies rather than one’s own currency, it is much harder for a country’s policy makers to do the sorts of things that spread out the debt problems, and 2) the fact that debt crises can be well-managed does not mean that they are not extremely costly to some people.
>
> The key to handling debt crises well lies in policy makers’ knowing how to use their levers well and having the authority that they need to do so, knowing at what rate per year the burdens will have to be spread out, and who will benefit and who will suffer and in what degree, so that the political and other consequences are acceptable.

```
set levers [ austerity  defaults-restructure  print-money  redistribute-wealth ] 
if debt-service < income-cash-flow or debt-income-ratio < threshold or growth-rate > interest-rate and inflation-rate < threshold [ set deleveraging-beautifully? true ]
if austerity? or default? [ set economy-state deflationary set debt-reduced? true]
if print-money? [ set economy-state inflationary set growth-stimulated? true ]
```

> 1) Austerity (i.e., spending less)
> 2) Debt defaults/restructurings
> 3) The central bank “printing money” and making purchases (or providing guarantees)
> 4) Transfers of money and credit from those who have more than they need to those who have less
>
>