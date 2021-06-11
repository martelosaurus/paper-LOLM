# ------------------------------------------------------------------------------
library(data.table)
library(zoo)

dummy=TRUE

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
	X=X[!is.na(amount)&amount>0]

	# column types
	X[, amount := as.numeric(amount)]
	X[, valuation := as.numeric(valuation)]
	X[, equity.invested := as.numeric(equity.invested)]

	# calculate total investment per round reported at fund level 
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

	# maximum number of leads (and labels)
	L = max(X[,nleads])
	L = 3
	lead_firms = paste("lead.firm",1:L,sep=".")
	#X[,c(lead_firm):=.SD[lead.firm,],by=.(company.id,round.number)]

	X[nleads >= 1L, lead.firm.1 := na.exclude(unique(lead.firm))[1], by=.(company.id, round.number)]
	X[nleads >= 2L, lead.firm.2 := na.exclude(unique(lead.firm))[2], by=.(company.id, round.number)]
	X[nleads >= 3L, lead.firm.3 := na.exclude(unique(lead.firm))[3], by=.(company.id, round.number)]

	X[, nleads := NULL]
	if (TRUE) {

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
	X=unique(X)

	# add cumulative amount and equity (for filtering purposes)
	X[,cum.equity:=cumsum(equity),by=.(company.id)]
	X[,cum.amount:=cumsum(amount),by=.(company.id)]

	# drop rounds with no reported investment up to that point 
	X=X[cum.equity>0]

	# figure out if previous round is in (otherwise data is useless)
	setkey(X, company.id, round.number)
	X[,last.round:=shift(round.number,type="lag"),by=company.id]
	X[,last.round:=ifelse(is.na(last.round),0L,last.round)]
	X[,last.in:=ifelse(last.round==(round.number-1),1L,0L)]

	# check that valuation and amount reported for all rounds
	X[,round.Return:=(valuation-amount)/shift(valuation),by=company.id]
	X[,round.Return:=ifelse(is.na(round.Return),1,round.Return)]
	X[,cum.Return:=cumprod(round.Return),by=company.id]

	# --------------------------------------------------------------------------
	# fill-in missing lead firms
	setkey(X, company.id, round.number)

	# if lead.firm.1 is NA, then the current lead is the last lead
	X[,lead.firm.1:=na.locf(lead.firm.1),by=company.id]

	# lag some values to figure out lead changes
	L=3
	last_leads = paste("last.lead",1:L,sep=".")
	X[,c(last_leads):=shift(.SD[,lead_firms,with=F]),by=company.id]

	# --------------------------------------------------------------------------
	# lead change 

	# if all of the leads are new, then a lead change has occurred
	setkey(X, company.id, round.number)
	X[, lead.change := !any(na.exclude(c(lead.firm.1, lead.firm.2, lead.firm.3)) %in% na.exclude(c(last.lead.1, last.lead.2, last.lead.3))), by=index(X)]

	# check that all last rounds are included 
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
	X[,fraction.reported:=cum.equity/cum.amount]
	X=X[fraction.reported>=.8]

	# Lead change to undisclosed firm - unclear whether to exclude or allow 
	# (could add noise - but also informative)
	X=X[lead.firm.1!="Undisclosed Firm"]
	X=X[last.lead.1!="Undisclosed Firm"]

	# more filters
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

	# check against old version
	load("control.RData")
	X[,lead.change:=1L*lead.change]
	X[,valuation.adj:=valuation-amount]
	X=X[!is.na(valuation.adj)]
	if (all(X %in% dt_vca)) {print("SUCCESS")}

	# factor and drop
	X=X[,.(last.investment.date,investment.date,duration,logret)]
	factor_yq=function(x.date) factor(year(x.date)):factor(quarter(x.date))
	X[,t.buy.yq:=factor_yq(last.investment.date)]
	X[,T.buy.yq:=factor_yq(investment.date)]
	X[,c("last.investment.date","investment.date"):=NULL]
	#save(X,file="venture_capital.RData")
	
}}
