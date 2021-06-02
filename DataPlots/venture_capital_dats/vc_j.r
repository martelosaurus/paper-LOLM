options(stringsAsFactors=FALSE)
library(data.table) 
library(mgcv) 
library(ggplot2) 
library(foreign)
library(lfe)

#nafix=function(x,f) ifelse(is.na(x),f,x)
nafix=function(x,f) ifelse(is.na(x),NA,x)

# NOTES:
#	- "company.id" refers to the company in which VC funds invest
#	- "firm.name" refers to a VC fund
#	- The lead VC investor changes when the investor with the greatest
#	  cumulative investment changes

# load data
if (is.element("venture_capital.RData",list.files())) {
	load("venture_capital.RData")
} else {


	# load data
	X = data.table(read.csv("venture_capital_raw.csv"))
	setkey(X,company.id,round.number)
	vars=c("amount","valuation","equity.invested")
	X[,paste(vars):=lapply(.SD[,vars,with=FALSE],as.numeric)]
	X=subset(X,company.id!="-"&!is.na(amount)&amount>0)

	rtf = function(x) all(unique(x)==seq(1,max(x)))
	X = X[,round.tag:=rtf(.SD[,round.number]),by=.(company.id)]
	X = subset(X,round.tag)
	X[,max.round:=max(.SD[,round.number]),by=.(company.id)]
	X = subset(X,max.round>1)

    # total equity invested in each round
    X[,equity.total:=sum(equity.invested,na.rm=TRUE),by=.(company.id,round.number)]

    # cumulative total investment by firm
    #setkey(X,company.id,round.number,firm.name)
    #X[,equity.invested.nafix:=nafix(equity.invested,0)]
	##---
	#X[,valuation := ifelse(!is.na(valuation), valuation, 0)]
	#X[,equity.invested:=NULL]
	##--
    #X[,cum.inv.by.firm:=cumsum(equity.invested.nafix),by=.(company.id, firm.name)]
    # cumulative total investment by firm
    setkey(X,company.id,round.number,firm.name)
    X[,equity.invested.nafix:=nafix(amount,0)]
	X[,valuation := ifelse(!is.na(valuation), valuation, 0)]
	X[,equity.invested:=NULL]
    X[,cum.inv.by.firm:=cumsum(equity.invested.nafix),by=.(company.id, firm.name)]

    # highest cumulative total investment as of current round
    X[,max.cum.inv.by.firm:=max(cum.inv.by.firm),by =.(company.id, round.number)]

    # adjust if there was a higher one in the previous round
    X[,max.cum.inv.cum:=cummax(max.cum.inv.by.firm),by=.(company.id)]

	# identify the lead VC
    X[,lead.vc:=ifelse(cum.inv.by.firm==max.cum.inv.cum&cum.inv.by.firm>0,1,0)]
	X[firm.name=="Undisclosed Firm",lead.vc:=0L]

    # multiple lead VCs
    X[,nleads:=as.integer(sum(lead.vc)),by =.(company.id, round.number)]
    X[,lead.firm:=ifelse(lead.vc==1,firm.name,NA)]

	# NUMBER OF LEADS
	setkey(X,company.id,round.number,firm.name)
	write.csv(X,file="jv.csv",row.names=FALSE)
	print(nrow(X))
if (FALSE) {

	###
	### Before this: data is one record per investment firm round

    # remove repeat funds 
    setorder(X,company.id,round.number)
    X=unique(X,by=c("company.id","firm.name"),fromLast=TRUE)

	### After this: data is one record per company.id/round
	###

    # Add cumulative amount and equity (for filtering purposes)
    X[,c("cum.equity","cum.amount"):=lapply(.(equity.total,amount),cumsum),by=company.id]
    X=subset(X,cum.equity>0)

    # Figure out if prior round is in, otherwise data is useless
    setkey(X,company.id,round.number)
    X[,prior.round:=nafix(shift(round.number,type="lag"),0L),by=company.id]
    X[,prior.in:=ifelse(prior.round==(round.number-1L),1L,0L)]
    X[,valuation.adj:= valuation-amount] # adjusted valuation 
    X[,prior.valuation:=shift(valuation,type="lag"),by=company.id]
    X[,round.Return:=nafix(valuation.adj/prior.valuation,1L)]
    X[,cum.Return:=cumprod(round.Return),by=company.id]

    # compute lagged values
    setkey(X,company.id,round.number)
    vars1=c("lead.date","lead.round","valuation","cum.Return")
    vars0=c("investment.date","round.number","valuation","cum.Return")
    X[,paste("prior",vars1,sep="."):=shift(.SD[,vars0,with=FALSE],type="lag"),by=company.id]
    X[,yearChange:=year(investment.date)]
    X[,yearFirst:=year(prior.lead.date)]
	print("compute lagged values")

    # define log-logret
    X=subset(X,!is.na(valuation.adj)&!is.na(prior.valuation))
    X=subset(X,cum.Return>0&prior.cum.Return>0)
    X[,logret:=log(cum.Return/prior.cum.Return)] 
    
    # define duration
    X[,duration:=as.numeric(investment.date-prior.lead.date)/365]
    X=subset(X,duration>0)

    save(X,file="venture_capital.RData")
}
}

