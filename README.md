# Learning by Owning in a Lemons Market

Forthcoming at the  *Journal of Finance*. Most of this code was written by or in collaboration with Brian Waters (University of Colorado Boulder).

## Empirical work
In the paper, we look at three applications. To generate the plots in the paper, run
```R
source("wrapper.r")
```

### Housing 
The data on sales of residential real estate are from Zillow's ZTrax database and include transactions from 1900 to 2016. Our sample includes all repeat transactions of single-family, detached homes in 31 US states (including the district) for which we have data and in which the transaction price was recorded at the time of sale. Data generously provided by Ryan Lewis (University of Colorado Boulder) and include transaction from AL, AK, CA, CT, DC, DE, FL, GA, HI, IL, IN, LA, ME, MD, MA, MI, MN, MS, NH, NJ, NY, NC, OH, OR, PA, RI, SC, TX, VA, WA, and WI. For many housing transactions, prices are imputed from sales tax filings rather than recorded at the time of sale. To avoid measurement error, the data exclude such sales. 

Field | Description
----- | -----------
salespriceamount | Transaction price
importparcelid | Parcel ID
sqrt | Square footage
documentdate |

### Venture Capital 
To analyze changes in lead VC investors, we use data from VentureXpert covering financing rounds from 1970 to 2015.


Field | Description
----- | -----------
investment.date | Date on which firms invest
company.id | Name of the company in which firms invest
firm.name | Name of the venture capital
round.number | Round number
amount | Disclosed amount of equity invested prior to the round
equity.invested | Fund known equity invested in company at investment date 
n.funds | Number of funds at investment date,
valuation | Valuation at transaction date 

All values are in millions of USD.

### Equipment

The data on sales of heavy equipment are from EquipmentWatch and include US transactions that occurred between 1994 and 2013. To construct the sample used in our analysis, we include all US repeated transactions across all vehicles in the EquipmentWatch database with a length of ownership between one day and ten years. 

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

