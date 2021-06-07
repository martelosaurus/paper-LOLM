# Learning by Owning in a Lemons Market

Forthcoming at the  *Journal of Finance*. Most of this code was written by or in collaboration with Brian Waters.

## Empirical work
In the paper, we look at three applications.

### Housing 
The data on sales of residential real estate are from Zillow's ZTrax database and include transactions from 1900 to 2016. Our sample includes all repeat transactions of single-family, detached homes in 31 US states (including the district) for which we have data and in which the transaction price was recorded at the time of sale.\footnote{Data generously provided by Ryan Lewis and include transaction from AL, AK, CA, CT, DC, DE, FL, GA, HI, IL, IN, LA, ME, MD, MA, MI, MN, MS, NH, NJ, NY, NC, OH, OR, PA, RI, SC, TX, VA, WA, and WI. For many housing transactions, prices are imputed from sales tax filings rather than recorded at the time of sale. To avoid measurement error, the data exclude such sales.} We restrict our attention to homes with a length-of-ownership between 1 day and fifteen years. The pattern in housing returns is qualitatively unchanged if we include longer holding periods. Figure \ref{f-homeHist} plots the distribution of lengths-of-ownership in our sample. Finally, in order to reduce the impact of remodelling on holding period returns, we remove all properties for which there was a change in square-footage across transactions.

Field | Description
----- | -----------
salespriceamount | Transaction price
importparcelid | Parcel ID
sqrt | Square footage
documentdate |


### Venture Capital 
To draw parallels between an asset sale in our model and the choice to dilute ownership in staged funding, we restrict our analysis to financing rounds in which there is a meaningful change in firm ownership.  For our purposes, we interpret a financing round in which there is a change in the identity of the lead venture capital investor as equivalent to an asset sale in which the portfolio company is "sold" from the previous lead investor to a new lead investor.  Along these lines, Cumming and Dai (2013) define a change in lead VC investor as a change in the identity of the investment firm which has contributed the greatest cumulative investment at any point in the life of a startup company, and show that nearly 25\% of follow-on rounds of funding have a different lead VC than those in earlier rounds.

To analyze changes in lead VC investors, we use data from VentureXpert covering financing rounds from 1970 to 2015. To construct our sample of changes in lead venture capital investors, we begin with all portfolio companies with at least two reported financing rounds from 1970 to 2015.  We follow Cumming and Dai (2013) and define a change in lead VC investor as a change in the identity of the investment firm which has made the greatest cumulative investment during the life of a startup company.  In order to calculate the identity of the lead venture capital investor, we must observe investment contributions by round at the investment firm level.  We therefore exclude lead VC changes if, prior to the change, the portfolio company has had at least one unreported financing round and/or greater than 20\% of investment is not reported at the investment firm level.  In addition, we drop lead changes in which, following our selection process, the lead investor is labelled as "Undisclosed Firm."  If more than one investment firm has contributed the same cumulative investment at any point in time, each firm is considered to be the lead investor at that time.  In this case, we classify a change in lead investor as the time (following round 1) when an investor who has not previously been a lead investor first becomes a lead investor. Finally, we exclude lead changes with length of ownership smaller than three months or greater than two-and-a-half years, since we have only limited data covering very short or long holding periods.


Field | Description
----- | -----------
investment.date | 
company.id |
firm.name |
round.number |
amount | Disclosed amount of equity invested 
equity.invested | Fund known equity invested in company at investment date 
n.funds | Number of funds at investment date,
valuation | Valuation at transaction date 

All values are in millions of USD.

### Equipment

The data on sales of heavy equipment are from EquipmentWatch and include US transactions that occurred between 1994 and 2013. To construct the sample used in our analysis, we include all US repeated transactions across all vehicles in the EquipmentWatch database with a length of ownership between one day and ten years. In Figure \ref{f-equipHist}, we plot the distribution of lengths-of-ownership in our sample.

In Figure \ref{f-equipReturn}, we plot our main finding, which is a U-shape of log-returns in the length-of-ownership for heavy equipment, adjusted for depreciation.\footnote{Using similar data, Murfin and Pratt (2019) show that equipment models backed by captive financing retain higher resale values. While this may lead to differential depreciation rates across heavy equipment models, it is unlikely to explain the U-shape in holding period returns that we document in Figure \ref{f-equipReturn}.} This adjustment is especially important for heavy equipment, which can experience substantial physical depreciation. To adjust for depreciation, we residualize holding period returns with fixed effects for the age in years at the time the equipment is purchased and the age in years at the time the equipment is sold. where is the price at which a piece of equipment was sold and is the price at which a piece of equipment was initially purchased. To control for physical depreciation, we include separate fixed effects for the age in years at the time of purchase  and the age in years at the time of sale . Figure \ref{f-equipReturn} plots the relationship between the residuals from this regression  on the length of ownership $T-t$. For comparison, Figure \ref{fig:equipment_rawrets} plots unadjusted log holding period returns. Unadjusted returns are generally decreasing as equipment depreciates as it ages. In addition, Figure \ref{fig:equipment_rotrets} adjusts for depreciation by removing the best-fit constant depreciation rate of 8.0\% per year. Figure \ref{fig:equipment_rotrets} is consistent with our primary specification in Figure \ref{f-equipReturn} and confirms a U-shape in holding period returns for heavy equipment after adjusting for depreciation.

Field | Description
----- | -----------
manufacturer | 
model | 
year.built | 
serial.number | 
date | 
auction.price | 
condition | 
country.code | 


## Numerical work

### Perfect Good News

### Brownian Motion

