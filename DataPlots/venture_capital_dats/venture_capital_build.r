# ------------------------------------------------------------------------------
library(data.table)
library(ggplot2)
library(mgcv)
library(plyr)
library(lfe)
library(zoo)

dummy=F

# load data
if (is.element("venture_capital.RData",list.files())) {
	load("venture_capital.RData")
} else {

    # --------------------------------------------------------------------------
	# load and clean data

	# load data
	if (dummy) {
		X=data.table(read.csv("dummy.csv"))
	} else {
		X=data.table(read.csv("venture_capital_raw.csv",stringsAsFactors=F))
	}

	# format date 
	X[,investment.date:=as.Date(investment.date,format="%Y-%m-%d")]

	# drop missing company id
	X=X[company.id != "-"]

	# column types
	X[, amount := as.numeric(amount)]
	X[, valuation := as.numeric(valuation)]
	X[, equity.invested := as.numeric(equity.invested)]

	# drop missing round investment amount
	X=X[!is.na(amount)]
	X=X[amount>0]

	# calculate total investment per round reported at fund level 
	# (used for comparison with fund round amount)
	X[,equity:=sum(equity.invested,na.rm=T),by=.(company.id, round.number)]
	

    # --------------------------------------------------------------------------
	# identify lead investors

	# cumulative total investment by firm
	setkey(X,company.id,round.number,firm.name)
	X[,equity.invested:=ifelse(!is.na(equity.invested),equity.invested,0)]
	X[,cum.inv.by.firm:=cumsum(equity.invested),by=.(company.id,firm.name)]

	# highest cumulative total investment as of current round
	X[,max.cum.inv.by.firm:=max(cum.inv.by.firm),by=.(company.id,round.number)]

	# adjust if there was a higher one in the previous round
	X[,max.cum.inv.cum:=cummax(max.cum.inv.by.firm),by=.(company.id)]
	X[,lead.vc:=ifelse(cum.inv.by.firm==max.cum.inv.cum&cum.inv.by.firm>0,T,F)]

	## Multiple leads, put in multiple columns (max 6)
	X[,nleads:=as.integer(sum(lead.vc)),by=.(company.id,round.number)]
	X[,lead.firm:=ifelse(lead.vc==T,firm.name,NA)]

	# COMPUTE MAXIMUM NUMBER OF LEADS
	L = max(X[,nleads])
	#X[,paste("lead.firm",1:max_leads):=,by=.(company.id,round.number)]

	X[nleads >= 1L, lead.firm.1 := na.exclude(unique(lead.firm))[1], by=.(company.id, round.number)]
	X[nleads >= 2L, lead.firm.2 := na.exclude(unique(lead.firm))[2], by=.(company.id, round.number)]
	X[nleads >= 3L, lead.firm.3 := na.exclude(unique(lead.firm))[3], by=.(company.id, round.number)]

	X[, nleads := NULL]

	setkey(X, company.id, investment.date)
	
	# purge remaining unused fields
	X[, firm.name := NULL] # removing adds a bunch of obs
	X[, equity.invested := NULL]
	X[, cum.inv.by.firm := NULL]
	X[, max.cum.inv.by.firm := NULL]
	X[, lead.vc := NULL]
	X[, lead.firm := NULL]

	### Before this: data is one record per investment firm round
	### After this: data is one record per company.id/round
	# collapse to to company.id/round
	X=unique(X)

	# add cumulative amount and equity (for filtering purposes)
	X[,cum.equity:=cumsum(equity),by=.(company.id)]
	X[,cum.amount:=cumsum(amount),by=.(company.id)]

	# drop rounds with no reported investment up to that point 
	# (helps to eliminate NA lead investor later on)
	X=X[cum.equity>0]

	# figure out if previous round is in (otherwise data is useless)
	setkey(X, company.id, round.number)
	X[,last.round:=shift(round.number,type="lag"),by=company.id]
	X[,last.round:=ifelse(is.na(last.round),0L,last.round)]
	X[,last.in:=ifelse(last.round==(round.number-1),1L,0L)]

	# check that valuation and amount reported for all rounds
	X[,valuation.adj:=valuation-amount]
	X[,round.Return:=(valuation-amount)/shift(valuation),by=company.id]
	X[,round.Return:=ifelse(is.na(round.Return),1,round.Return)]
	X[,cum.Return:=cumprod(round.Return),by=company.id]

	# --------------------------------------------------------------------------
	# fill-in missing lead firms
	lead_firms = paste("lead.firm",1:L,sep=".")
	last_leads = paste("last.lead",1:L,sep=".")
	setkey(X, company.id, round.number)
	#X[is.na(lead.firm.1),lead.firms:=.SD[,last.leads],by=company.id]
	#X[,last_leads:=shift(.SD[,lead_firms,with=F]),by=company.id]

	# if lead.firm.1 is NA, then last leads are retained 

	# lag some values to figure out lead changes
	X[,lead.firm.1:=nafill(lead.firm.1,type="locf")]
	X[,last.lead.1:=c(NA,head(lead.firm.1,-1)),by=company.id]
	X[,last.lead.2:=c(NA,head(lead.firm.2,-1)),by=company.id]
	X[,last.lead.3:=c(NA,head(lead.firm.3,-1)),by=company.id]


	if (FALSE) {
	# if lead.firm.1 is NA, last leads should be retained (ideally recursively, but two steps enough here)
	
	X[is.na(lead.firm.1), lead.firm.1 := last.lead.1]

	## Circle through lasts once more
	setkey(X, company.id, round.number)
	X[, last.lead.1 := c(NA,head(lead.firm.1,-1)), by=company.id]

	## If lead.firm.1 is NA, last leads should be retained (ideally recursively, but two steps enough here)
	X[is.na(lead.firm.1), lead.firm.1 := last.lead.1]

	## Circle through lasts once more
	setkey(X, company.id, round.number)
	X[, last.lead.1 := c(NA,head(lead.firm.1,-1)), by=company.id]
	}

	# --------------------------------------------------------------------------
	# lead change 

	# if all of the leads are new, then a lead change has occurred
	setkey(X, company.id, round.number)
	X[, uid := 1:.N]
	X[, lead.change := ifelse( any(na.exclude(c(lead.firm.1, lead.firm.2, lead.firm.3)) %in% na.exclude(c(last.lead.1, last.lead.2, last.lead.3))), 0L, 1L), by=uid]

	# if the lead firm is NA, there was no lead change (but this shouldn't happen?)
	X[is.na(lead.firm.1),lead.change:=F]

	# check that all last rounds are included (last.in.sum == round.number, cut is further down)
	X[,last.in.sum:=cumsum(last.in),by=company.id]
	X=X[round.number==last.in.sum]

	# save only lead changes (and first round)
	X=X[lead.change==1L|round.number==1L]

	# lag value and date to create return and time change between lead changes
	setkey(X, company.id, round.number)

	# lag value and date to create return and time change between lead changes
	cols = c("investment.date","round.number","valuation","cum.Return")
	X[,paste("last",cols,sep="."):=shift(.SD[,cols,with=F]),by=company.id]

	# --------------------------------------------------------------------------
	# more filters

	# X%+ of all investments must be accounted for 
	# (should be up until change)
	X[,fraction.reported:=cum.equity/cum.amount]
	X=X[fraction.reported >= .8]

	# Lead change to undisclosed firm - unclear whether to exclude or allow 
	# (could add noise - but also informative)
	X=X[lead.firm.1!="Undisclosed Firm"]
	X=X[last.lead.1!="Undisclosed Firm"]

	# Now create plots following same procedure as with machine data
	X=X[!is.na(valuation.adj)]
	X=X[!is.na(last.valuation)]
	X=X[last.cum.Return>0] 

	# compute log return and duration, then order by duration
	X[,logret:=log(cum.Return/last.cum.Return)] 
	X[,duration:=as.numeric(investment.date-last.investment.date)]
	setorder(X,duration)

	# keep non-zero durations
	X=X[duration>0]

	# --------------------------------------------------------------------------
	# drop
	load("control.RData")
	if (all(X %in% dt_vca)) {print("SUCCESS")}
	X=X[,.(last.investment.date,investment.date,duration,logret)]
	factor_yq=function(x.date) factor(year(x.date)):factor(quarter(x.date))
	X[,t.buy.yq:=factor_yq(last.investment.date)]
	X[,T.buy.yq:=factor_yq(investment.date)]
	X[,c("last.investment.date","investment.date"):=NULL]
	#save(X,file="venture_capital.RData")
	
}
