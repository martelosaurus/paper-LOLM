# ------------------------------------------------------------------------------
library(data.table) 
library(mgcv) 
library(ggplot2) 
library(foreign)
library(lfe)

nafix=function(x,f) ifelse(is.na(x),f,x)

# NOTES:
#	- "company.id" refers to the company in which VC funds invest
#	- "firm.name" refers to a VC fund

# load data
if (is.element("venture_capital.RData",list.files())) {
	load("venture_capital.RData")
} else {

	# load data
	X = data.table(read.csv("venture_capital_raw.csv"))    

	# Drop missing company id
	X = X[company.id != "-"]

	# Column types
	X[, amount := as.numeric(amount)]
	X[, valuation := as.numeric(valuation)]
	X[, equity.invested := as.numeric(equity.invested)]

	# Drop missing round investment amount
	X = X[!is.na(amount)]
	X = X[amount>0]

    #as.numeric.plus=function(v) ifelse(v=="-",NA,as.numeric(v))
    #vars=c("amount","valuation","equity.invested")
    #X[,paste(vars):=lapply(.SD[,vars,with=FALSE],as.numeric.plus)]
    #X=subset(X,!is.na(amount)&amount>0&!is.na(valuation))	

	# Calculate total investment per round reported at fund level (used for 
	# comparison with fund round amount)
	X[, equity.total := sum(equity.invested, na.rm=TRUE), 
		   by = .(company.id, round.number)]

	# cumulative total investment by firm
	setkey(X,company.id,round.number,firm.name)
	X[,equity.invested.nafix:=ifelse(!is.na(equity.invested),equity.invested,0)]
	X[,cum.inv.by.firm:=cumsum(equity.invested.nafix),by=.(company.id, firm.name)]

	# highest cumulative total investment as of current round
	X[,max.cum.inv.by.firm:=max(cum.inv.by.firm),by=.(company.id, round.number)]

	# adjust if there was a higher one in the previous round
	X[,max.cum.inv.cum:=cummax(max.cum.inv.by.firm),by=.(company.id)]
	X[,lead.vc:=ifelse(cum.inv.by.firm==max.cum.inv.cum&cum.inv.by.firm>0,1L,0L)]

	# Multiple leads, put in multiple columns (max 6)
	X[,nleads:=as.integer(sum(lead.vc)),by=.(company.id,round.number)]
	X[,lead.firm:=ifelse(lead.vc==1L,firm.name,NA)]
	for (j in 1:6) {
	X[nleads>=1L,lead.firm.1:=na.exclude(unique(lead.firm))[1],by=.(company.id,round.number)]
	X[nleads>=2L,lead.firm.2:=na.exclude(unique(lead.firm))[2],by=.(company.id,round.number)]
	X[nleads>=3L,lead.firm.3:=na.exclude(unique(lead.firm))[3],by=.(company.id,round.number)]
	X[nleads>=4L,lead.firm.4:=na.exclude(unique(lead.firm))[4],by=.(company.id,round.number)]
	X[nleads>=5L,lead.firm.5:=na.exclude(unique(lead.firm))[5],by=.(company.id,round.number)]
	X[nleads>=6L,lead.firm.6:=na.exclude(unique(lead.firm))[6],by=.(company.id,round.number)]
	}

	X[,nleads:=NULL]

	# Minimum round
	X[,min.round:=min(round.number,na.rm=TRUE),by=company.id]

	## ------------------------------------------------------------------------- ##
	## Before this: data is one record per investment firm round				 ##
	## After this: data is one record per company.id/round						 ##
	## ------------------------------------------------------------------------- ##

	# From here: order it correctly, collapse on company/round and do calculations.
	# - remove columns that dont contain round aggregated information
	setkey(X, company.id, investment.date)
	X[,firm.name:=NULL]
	X[,fund.name:=NULL]
	X[,equity.invested:=NULL]
	X[,equity.invested.nafix:=NULL]
	X[,cum.inv.by.firm:=NULL]
	X[,max.cum.inv.by.firm:=NULL]
	X[,lead.vc:=NULL]
	X[,lead.firm:=NULL]
	X = unique(X)


	# Add cumulative amount and equity (for filtering purposes)
	X[, cum.equity := cumsum(equity.total), by = .(company.id)]
	X[, cum.amount := cumsum(amount), by = .(company.id)]

	# Drop rounds with no reported investment up to that point (helps to eliminate NA lead investor later on)
	X = X[cum.equity>0]

	# Figure out if prior round is in, otherwise data is useless
	setkey(X, company.id, round.number)
	X[, prior.round := c(NA,head(round.number,-1)), by = company.id]
	X[, prior.round := ifelse(is.na(prior.round), 0L, prior.round)]
	X[, prior.in := ifelse(prior.round == (round.number - 1L), 1L, 0L)]

	## Net out current investment: that is calc pre-money value
	X[, valuation.adj := valuation - amount] 
	## Check that valuation and amount reported for all rounds
	X[, prior.valuation := c(NA,valuation[-.N]), by = company.id]
	X[, round.Return := valuation.adj/prior.valuation]
	X[, round.Return := ifelse(is.na(round.Return), 1L, round.Return)]
	X[, cum.Return := cumprod(round.Return), by = .(company.id)]

	# Lag some values to figure out lead changes
	setkey(X, company.id, round.number)
	X[, prior.lead.1 := c(NA,head(lead.firm.1,-1)), by = company.id]
	X[, prior.lead.2 := c(NA,head(lead.firm.2,-1)), by = company.id]
	X[, prior.lead.3 := c(NA,head(lead.firm.3,-1)), by = company.id]
	X[, prior.lead.4 := c(NA,head(lead.firm.4,-1)), by = company.id]
	X[, prior.lead.5 := c(NA,head(lead.firm.5,-1)), by = company.id]
	X[, prior.lead.6 := c(NA,head(lead.firm.6,-1)), by = company.id]

	# If lead.firm.1 is NA, prior leads should be retained 
	# (ideally recursively, but two steps enough here)
	X[is.na(lead.firm.1), lead.firm.1 := prior.lead.1]
	X[is.na(lead.firm.1), lead.firm.2 := prior.lead.2]
	X[is.na(lead.firm.1), lead.firm.3 := prior.lead.3]
	X[is.na(lead.firm.1), lead.firm.4 := prior.lead.4]
	X[is.na(lead.firm.1), lead.firm.5 := prior.lead.5]
	X[is.na(lead.firm.1), lead.firm.6 := prior.lead.6]

	# Circle through priors once more
	setkey(X, company.id, round.number)
	X[, prior.lead.1 := c(NA,head(lead.firm.1,-1)), by = company.id]
	X[, prior.lead.2 := c(NA,head(lead.firm.2,-1)), by = company.id]
	X[, prior.lead.3 := c(NA,head(lead.firm.3,-1)), by = company.id]
	X[, prior.lead.4 := c(NA,head(lead.firm.4,-1)), by = company.id]
	X[, prior.lead.5 := c(NA,head(lead.firm.5,-1)), by = company.id]
	X[, prior.lead.6 := c(NA,head(lead.firm.6,-1)), by = company.id]

	# If lead.firm.1 is NA, prior leads should be retained 
	# (ideally recursively, but two steps enough here)
	X[is.na(lead.firm.1), lead.firm.1 := prior.lead.1]
	X[is.na(lead.firm.1), lead.firm.2 := prior.lead.2]
	X[is.na(lead.firm.1), lead.firm.3 := prior.lead.3]
	X[is.na(lead.firm.1), lead.firm.4 := prior.lead.4]
	X[is.na(lead.firm.1), lead.firm.5 := prior.lead.5]
	X[is.na(lead.firm.1), lead.firm.6 := prior.lead.6]

	# Circle through priors once more
	setkey(X, company.id, round.number)
	X[, prior.lead.1 := c(NA,head(lead.firm.1,-1)), by = company.id]
	X[, prior.lead.2 := c(NA,head(lead.firm.2,-1)), by = company.id]
	X[, prior.lead.3 := c(NA,head(lead.firm.3,-1)), by = company.id]
	X[, prior.lead.4 := c(NA,head(lead.firm.4,-1)), by = company.id]
	X[, prior.lead.5 := c(NA,head(lead.firm.5,-1)), by = company.id]
	X[, prior.lead.6 := c(NA,head(lead.firm.6,-1)), by = company.id]

	# Lead change? 
	# If none of the current lead firms was a lead firm before, I want to mark it as lead change
	# potential issue: lead did not invest in the prior round and it is therefore NA
	setkey(X, company.id, round.number)
	X[, uid := 1:.N]
	X[, lead.change := ifelse(
	  any(na.exclude(c(lead.firm.1, lead.firm.2, lead.firm.3, 
					   lead.firm.4, lead.firm.5, lead.firm.6)) %in%
			na.exclude(c(prior.lead.1, prior.lead.2, prior.lead.3, 
						 prior.lead.4, prior.lead.5, prior.lead.6))),
	  0L, 1L), by = uid]


	# If the lead firm is NA, there was no lead change
	X[is.na(lead.firm.1), lead.change := 0L]

	# Check that all prior rounds are included (prior.in.sum == round.number, cut is further down)
	X[, prior.in.sum := cumsum(prior.in), by = company.id]
	X = X[round.number == prior.in.sum]

	setorder(X,company.name,round.number)

	# Save only lead changes (and first round - code should identify these as changes anyways)
	X = X[lead.change == 1L | round.number == 1L]

	# Lag value and date to create return and time change between lead changes
	setkey(X, company.id, round.number)
	X[, prior.lead.date := c(NA,investment.date[-.N]), by = company.id]
	class(X$prior.lead.date) = "Date"
	X[, prior.lead.round := c(NA,round.number[-.N]), by = company.id]
	X[, prior.valuation := c(NA,valuation[-.N]), by = company.id]
	X[, prior.cum.Return := c(NA,cum.Return[-.N]), by = company.id]

	# Filter(1) is that X%+ of all investments must be accounted for in all the rounds for the firm (should be up until change)
	X[, fraction.reported := cum.equity/cum.amount]
	X = X[fraction.reported >= .8]

	## Lead change to undisclosed firm - unclear whether to exclude or allow (could add noise - but also informative)
	X = X[lead.firm.1 != "Undisclosed Firm"]
	X = X[prior.lead.1 != "Undisclosed Firm"]

	## Now create plots following same procedure as with machine data
	X = X[!is.na(valuation.adj)]
	X = X[!is.na(prior.valuation)]
	X = X[prior.cum.Return>0] # Need to check why some values are 0
	X[,ln_Return := log(cum.Return/prior.cum.Return)] # check this #s seem low  
	X[,duration := as.numeric(investment.date-prior.lead.date)]
	setorder(X, duration)

	X[,Return := cum.Return/prior.cum.Return] # check this #s seem low  
	X[,durationYear:=duration/365]

	# Filter(2)
	X = X[durationYear>xmin]

	#JORDAN
	X=X[,.(prior.lead.date,investment.date,durationYear,ln_Return)]
	X[,t.purchase.yq:=factor(year(prior.lead.date)):factor(quarter(prior.lead.date))]
	X[,T.purchase.yq:=factor(year(investment.date)):factor(quarter(investment.date))]
	X[,c("prior.lead.date","investment.date"):=NULL]
	setnames(X,c("durationYear","ln_Return"),c("duration","logret"))
	Y = X
	#save(Y,file="venture_capital.RData")
	#JORDAN
}
