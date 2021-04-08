## Name:          *.R
## Author:        Brian Waters
## Last revision: 2017-03-30
##
## 1. Options
## 2. Data Input
## 3. Data Handling
## 4. Analysis
## 5. Output
##
## Description:
##
##

##################################################
## ------------- i. Functions ----------------- ##
##################################################

##################################################
## -------------- 1. Options ------------------ ##
##################################################
rm(list = ls())

options(stringsAsFactors=FALSE)
#library(gbells)
library(data.table)
library(foreign)
library(ggplot2)
library(mgcv)
#library(car)
library(plyr)
library(lfe)
#libraregmented)
library(zoo)

xmin = 1/365

"%P%" <- function(x,y) paste(x,y, sep="")

# if (FALSE) {
# folder = 'C:/Users/brwa6692/Dropbox/Experimentation in a Lemons Market/AER R&R/VX Data/'
# setwd("C:/Users/brwa6692/Dropbox/Experimentation in a Lemons Market/AER R&R/VX Data")
# }
#folder = 'C:/Users/Brian/Dropbox/Experimentation in a Lemons Market/AER R&R/VX Data/'
#setwd("C:/Users/Brian/Dropbox/Experimentation in a Lemons Market/AER R&R/VX Data")

##################################################
## ------------ 2. Data Input ----------------- ##
##################################################



## Combine all the files
#fns = dir(folder %P% "raw vc data")

dt_vca = data.table()

for(fn in list.files()) {
  #fn = fns[1]
  
 # dt_fri = data.table(read.csv(folder %P% "raw vc data/" %P% fn))
    if (grepl("Fund_round",fn)) {

        dt_fri = data.table(read.csv(fn))

          setnames(dt_fri, colnames(dt_fri), tolower(colnames(dt_fri)))
          
          cnames_to_rename = c('sic.code', 'naic.code', 
                               'equity.amount.disclosed..usd.mil.', 
                               'valuation.at.transaction.date..usd.mil.', 
                               'no..of.funds.at.investment.date', 
                               'fund.known.equity.invested.in.company.at.investment.date..usd.mil.')
          setnames(dt_fri, cnames_to_rename, c('sic', 'naics', 'amount', 'valuation',
                                               'n.funds', 'equity.invested'))
          
          dt_fri[, investment.date := as.Date(investment.date, format = "%m/%d/%Y")]
          
          stopifnot(class(dt_fri[,sic]) == "character")
          dt_fri[, sic2 := substring(sic, 1,2)]
          #dt_fri[company.id == "C000065382"]
          
          dt_vca = rbindlist(list(dt_vca, dt_fri))

    }
}

setkey(dt_vca, company.id, round.number)

##################################################
## ----------- 3. Data Handling --------------- ##
##################################################

#######
## Clean data
#######

## Drop missing company id
dt_vca = dt_vca[company.id != "-"]

## Column types
dt_vca[, amount := as.numeric(amount)]
dt_vca[, valuation := as.numeric(valuation)]
dt_vca[, equity.invested := as.numeric(equity.invested)]

## Drop missing round investment amount
dt_vca = dt_vca[!is.na(amount)]
dt_vca = dt_vca[amount>0]

## Calculate total investment per round reported at fund level (used for comparison with fund round amount)
# dt_vca = dt_vca[fund.name!="Undisclosed Fund"] ## Drop undisclosed firm - treat as if this amount is unreported
dt_vca[, equity.total := sum(equity.invested, na.rm=TRUE), 
       by = .(company.id, round.number)]


## Collapse on company/round/firm/
#dt_vca = dt_vca[, .(company.name, company.id, round.number, investment.date,
#                    sic, sic2, naics, amount, valuation, n.funds,
#                    firm.name, equity.total,
#                    equity.invested = sum(equity.invested,na.rm=TRUE)), 
#                by = .(company.id, round.number, firm.name)]


########
### Indicate lead investors
########

## cumulative total investment by firm
setkey(dt_vca, company.id, round.number, firm.name)
dt_vca[, equity.invested.nafix := ifelse(!is.na(equity.invested), equity.invested, 0)]
dt_vca[, cum.inv.by.firm := cumsum(equity.invested.nafix), by = .(company.id, firm.name)]
#dt_vca[, equity.invested.nafix := NULL]

## highest cumulative total investment as of current round
dt_vca[, max.cum.inv.by.firm := max(cum.inv.by.firm), by = .(company.id, round.number)]

## adjust if there was a higher one in the previous round
dt_vca[, max.cum.inv.cum := cummax(max.cum.inv.by.firm), by = .(company.id)]

dt_vca[, lead.vc := ifelse(cum.inv.by.firm == max.cum.inv.cum & cum.inv.by.firm > 0 , 1L, 0L)]
#dt_vca[firm.name == "Undisclosed Firm", lead.vc := 0L]

## Multiple leads, put in multiple columns (max 6)
dt_vca[, nleads := as.integer(sum(lead.vc)), by = .(company.id, round.number)]
dt_vca[, lead.firm := ifelse(lead.vc == 1L,firm.name,NA)]

print(nrow(dt_vca))

dt_vca[nleads >= 1L, lead.firm.1 := na.exclude(unique(lead.firm))[1], by = .(company.id, round.number)]
dt_vca[nleads >= 2L, lead.firm.2 := na.exclude(unique(lead.firm))[2], by = .(company.id, round.number)]
dt_vca[nleads >= 3L, lead.firm.3 := na.exclude(unique(lead.firm))[3], by = .(company.id, round.number)]
dt_vca[nleads >= 4L, lead.firm.4 := na.exclude(unique(lead.firm))[4], by = .(company.id, round.number)]
dt_vca[nleads >= 5L, lead.firm.5 := na.exclude(unique(lead.firm))[5], by = .(company.id, round.number)]
dt_vca[nleads >= 6L, lead.firm.6 := na.exclude(unique(lead.firm))[6], by = .(company.id, round.number)]

dt_vca[, nleads := NULL]

## Minimum round
dt_vca[, min.round := min(round.number, na.rm=TRUE), by = company.id ]

###
### Before this: data is one record per investment firm round
### After this: data is one record per company.id/round
###


# From here: order it correctly, collapse on company/round and do calculations.
# - remove columns that dont contain round aggregated information
setkey(dt_vca, company.id, investment.date)
dt_vca[, firm.name := NULL]
dt_vca[, fund.name := NULL]
dt_vca[, equity.invested := NULL]
dt_vca[, equity.invested.nafix := NULL]
dt_vca[, cum.inv.by.firm := NULL]
dt_vca[, max.cum.inv.by.firm := NULL]
dt_vca[, lead.vc := NULL]
dt_vca[, lead.firm := NULL]

dt_vca = unique(dt_vca)


## Add cumulative amount and equity (for filtering purposes)
dt_vca[, cum.equity := cumsum(equity.total), by = .(company.id)]
dt_vca[, cum.amount := cumsum(amount), by = .(company.id)]

## Drop rounds with no reported investment up to that point (helps to eliminate NA lead investor later on)
dt_vca = dt_vca[cum.equity>0]

## Figure out if prior round is in, otherwise data is useless
setkey(dt_vca, company.id, round.number)
dt_vca[, prior.round := c(NA,head(round.number,-1)), by = company.id]
dt_vca[, prior.round := ifelse(is.na(prior.round), 0L, prior.round)]
dt_vca[, prior.in := ifelse(prior.round == (round.number - 1L), 1L, 0L)]

### Net out current investment: that is calc pre-money value
dt_vca[, valuation.adj := valuation - amount] ### Check that valuation and amount reported for all rounds
dt_vca[, prior.valuation := c(NA,valuation[-.N]), by = company.id]
dt_vca[, round.Return := valuation.adj/prior.valuation]
dt_vca[, round.Return := ifelse(is.na(round.Return), 1L, round.Return)]
dt_vca[, cum.Return := cumprod(round.Return), by = .(company.id)]

## Lag some values to figure out lead changes
setkey(dt_vca, company.id, round.number)
dt_vca[, prior.lead.1 := c(NA,head(lead.firm.1,-1)), by = company.id]
dt_vca[, prior.lead.2 := c(NA,head(lead.firm.2,-1)), by = company.id]
dt_vca[, prior.lead.3 := c(NA,head(lead.firm.3,-1)), by = company.id]
dt_vca[, prior.lead.4 := c(NA,head(lead.firm.4,-1)), by = company.id]
dt_vca[, prior.lead.5 := c(NA,head(lead.firm.5,-1)), by = company.id]
dt_vca[, prior.lead.6 := c(NA,head(lead.firm.6,-1)), by = company.id]


## If lead.firm.1 is NA, prior leads should be retained (ideally recursively, but two steps enough here)
dt_vca[is.na(lead.firm.1), lead.firm.1 := prior.lead.1]
dt_vca[is.na(lead.firm.1), lead.firm.2 := prior.lead.2]
dt_vca[is.na(lead.firm.1), lead.firm.3 := prior.lead.3]
dt_vca[is.na(lead.firm.1), lead.firm.4 := prior.lead.4]
dt_vca[is.na(lead.firm.1), lead.firm.5 := prior.lead.5]
dt_vca[is.na(lead.firm.1), lead.firm.6 := prior.lead.6]

## Circle through priors once more
setkey(dt_vca, company.id, round.number)
dt_vca[, prior.lead.1 := c(NA,head(lead.firm.1,-1)), by = company.id]
dt_vca[, prior.lead.2 := c(NA,head(lead.firm.2,-1)), by = company.id]
dt_vca[, prior.lead.3 := c(NA,head(lead.firm.3,-1)), by = company.id]
dt_vca[, prior.lead.4 := c(NA,head(lead.firm.4,-1)), by = company.id]
dt_vca[, prior.lead.5 := c(NA,head(lead.firm.5,-1)), by = company.id]
dt_vca[, prior.lead.6 := c(NA,head(lead.firm.6,-1)), by = company.id]

## If lead.firm.1 is NA, prior leads should be retained (ideally recursively, but two steps enough here)
dt_vca[is.na(lead.firm.1), lead.firm.1 := prior.lead.1]
dt_vca[is.na(lead.firm.1), lead.firm.2 := prior.lead.2]
dt_vca[is.na(lead.firm.1), lead.firm.3 := prior.lead.3]
dt_vca[is.na(lead.firm.1), lead.firm.4 := prior.lead.4]
dt_vca[is.na(lead.firm.1), lead.firm.5 := prior.lead.5]
dt_vca[is.na(lead.firm.1), lead.firm.6 := prior.lead.6]

## Circle through priors once more
setkey(dt_vca, company.id, round.number)
dt_vca[, prior.lead.1 := c(NA,head(lead.firm.1,-1)), by = company.id]
dt_vca[, prior.lead.2 := c(NA,head(lead.firm.2,-1)), by = company.id]
dt_vca[, prior.lead.3 := c(NA,head(lead.firm.3,-1)), by = company.id]
dt_vca[, prior.lead.4 := c(NA,head(lead.firm.4,-1)), by = company.id]
dt_vca[, prior.lead.5 := c(NA,head(lead.firm.5,-1)), by = company.id]
dt_vca[, prior.lead.6 := c(NA,head(lead.firm.6,-1)), by = company.id]

## Lead change? 
## If none of the current lead firms was a lead firm before, I want to mark it as lead change
# potential issue: lead did not invest in the prior round and it is therefore NA
setkey(dt_vca, company.id, round.number)
dt_vca[, uid := 1:.N]
dt_vca[, lead.change := ifelse(
  any(na.exclude(c(lead.firm.1, lead.firm.2, lead.firm.3, 
                   lead.firm.4, lead.firm.5, lead.firm.6)) %in%
        na.exclude(c(prior.lead.1, prior.lead.2, prior.lead.3, 
                     prior.lead.4, prior.lead.5, prior.lead.6))),
  0L, 1L), by = uid]


## If the lead firm is NA, there was no lead change
dt_vca[is.na(lead.firm.1), lead.change := 0L]

## Check that all prior rounds are included (prior.in.sum == round.number, cut is further down)
dt_vca[, prior.in.sum := cumsum(prior.in), by = company.id]
dt_vca = dt_vca[round.number == prior.in.sum]

setorder(dt_vca,company.name,round.number)

## Save only lead changes (and first round - code should identify these as changes anyways)
dt_vca = dt_vca[lead.change == 1L | round.number == 1L]

## Lag value and date to create return and time change between lead changes
setkey(dt_vca, company.id, round.number)
dt_vca[, prior.lead.date := c(NA,investment.date[-.N]), by = company.id]
class(dt_vca$prior.lead.date) <- "Date"
dt_vca[, prior.lead.round := c(NA,round.number[-.N]), by = company.id]
dt_vca[, prior.valuation := c(NA,valuation[-.N]), by = company.id]
dt_vca[, prior.cum.Return := c(NA,cum.Return[-.N]), by = company.id]

#dt_vca = dt_vca[!is.na(prior.valuation.adj)]



## Remove all but first lead change
#setkey(dt_vca, company.id, round.number)
#dt_vca[, lead.change.counter := 1:.N, by = .(company.id)]
#dt_vca = dt_vca[lead.change.counter == 1]


#########
#### Check filters as last step
##########


## Filter(1) is that X%+ of all investments must be accounted for in all the rounds for the firm (should be up until change)
dt_vca[, fraction.reported := cum.equity/cum.amount]
dt_vca = dt_vca[fraction.reported >= .8]

### Lead change to undisclosed firm - unclear whether to exclude or allow (could add noise - but also informative)
dt_vca <- dt_vca[lead.firm.1 != "Undisclosed Firm"]
dt_vca <- dt_vca[prior.lead.1 != "Undisclosed Firm"]

### Now create plots following same procedure as with machine data
dt_vca = dt_vca[!is.na(valuation.adj)]
dt_vca = dt_vca[!is.na(prior.valuation)]
#dt_vca = dt_vca[prior.valuation.adj>0] 
dt_vca = dt_vca[prior.cum.Return>0] # Need to check why some values are 0
#dt_vca[,ln_Return := log(valuation.adj/prior.valuation.adj)]
dt_vca[,ln_Return := log(cum.Return/prior.cum.Return)] # check this #s seem low  LEFT OFF HERE
dt_vca[,duration := as.numeric(investment.date-prior.lead.date)]
setorder(dt_vca, duration)

dt_vca[,Return := cum.Return/prior.cum.Return] # check this #s seem low  LEFT OFF HERE

# Windsorize at 1% and 99%
#Rmax = quantile(dt_vca[,ln_Return],.99)
#Rmin = quantile(dt_vca[,ln_Return],.01)
#dt_vca[ln_Return>Rmax]$ln_Return <- Rmax
#dt_vca[ln_Return<Rmin]$ln_Return <- Rmin 

dt_vca[,durationYear:=duration/365]

# Filter(2)
#dt_vca = dt_vca[durationYear>0.25] #Remove misreported round data - also clear break in frequency of data beginning at 3 months
dt_vca = dt_vca[durationYear>xmin]
#dt_vca = dt_vca[durationYear<6]
#dt_vca = dt_vca[sic2=="73"]

#JORDAN
X<-dt_vca[,.(prior.lead.date,investment.date,durationYear,ln_Return)]
X[,t.purchase.yq:=factor(year(prior.lead.date)):factor(quarter(prior.lead.date))]
X[,T.purchase.yq:=factor(year(investment.date)):factor(quarter(investment.date))]
X[,c("prior.lead.date","investment.date"):=NULL]
setnames(X,c("durationYear","ln_Return"),c("duration","logret"))
Y = X
#save(Y,file="venture_capital.RData")
#JORDAN
