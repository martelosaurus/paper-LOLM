library(data.table) 
library(mgcv) 
library(ggplot2) 
library(foreign)
library(lfe)

# year-quarter-month----------------------------------------------------------#
yqm=function(data.date) {
	#
	# 	Convertes a date to a year-quarter-month list
	list(year(data.date),quarter(data.date),month(data.date))
}

if (is.element("housing.RData",list.files())) {
	load("housing.RData")
} else {

    # load the "catalyst"
	if (!is.element("catalyst.RData",list.files())) {

		#load("ztrax.RData") # subsets the orignal fields, then omits NAs 
		X = data.table(read.csv("housing.csv"))

		X=subset(X,!is.na(documentdate))
		X=unique(X,by=c("documentdate","importparcelid","salespriceamount"))
		X[,minmaxsqft:=max(sqft)-min(sqft),by=importparcelid]
		X=subset(X,minmaxsqft==0)

		# IMPORTANT: must be keyed on imortparcelid, then documentdate
		setkey(X,importparcelid,documentdate)
        X[,n.sales:=.N,by=importparcelid]
		X=subset(X,n.sales>1) # need at least two transaction

        X[,paste("t.purchase",c("y","q","m"),sep="."):=yqm(documentdate)]
        X[,documentdate.lead:=shift(documentdate,type="lead")]
        X[,paste("T.purchase",c("y","q","m"),sep="."):=yqm(documentdate.lead)]

		setkey(X,importparcelid,documentdate) # MUST BE KEYED 
        X[,duration:=(shift(documentdate,type="lead")-documentdate)/365,by=importparcelid]
        X[,logret:=log(shift(salespriceamount,type="lead")/salespriceamount),by=importparcelid]

		# CUTS
		X=na.omit(X)

		save(X,file="catalyst.RData")
	}

	# load the "catalyst" 
	load("catalyst.RData")

	X[,logret:=log(logret)]

    # manually factor returns
    X[,t.purchase.yq:=factor(t.purchase.y):factor(t.purchase.q)]
	X[,T.purchase.yq:=factor(T.purchase.y):factor(T.purchase.q)]

	# create duration bins
	X[,duration:=as.numeric(duration)]

	#save(X,file="housing.RData")
}
