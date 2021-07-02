library(data.table) 

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
		X = data.table(read.csv("housing.csv",stringsAsFactors=FALSE))	
		X[,documentdate:=as.Date(documentdate,format="%Y-%m-%d")]

		X=subset(X,!is.na(documentdate))
		X=unique(X,by=c("documentdate","importparcelid","salespriceamount"))
		X[,minmaxsqft:=max(sqft)-min(sqft),by=importparcelid]
		X=subset(X,minmaxsqft==0)

		# IMPORTANT: must be keyed on imortparcelid, then documentdate
		setkey(X,importparcelid,documentdate)
        X[,n.sales:=.N,by=importparcelid]
		X=subset(X,n.sales>1) # need at least two transaction

        X[,paste("t.buy",c("y","q","m"),sep="."):=yqm(documentdate)]
        X[,documentdate.lead:=shift(documentdate,type="lead"),by=importparcelid]
        X[,paste("T.buy",c("y","q","m"),sep="."):=yqm(documentdate.lead)]

		setkey(X,importparcelid,documentdate) # MUST BE KEYED 
        X[,duration:=as.numeric(documentdate.lead-documentdate)/365]
        X[,logret:=log(shift(salespriceamount,type="lead")/salespriceamount),by=importparcelid]

		# CUTS
		X=na.omit(X)

		save(X,file="catalyst.RData")
	}

	# load the "catalyst" 
	load("catalyst.RData")

    # manually factor returns
    X[,t.buy.yq:=factor(t.buy.y):factor(t.buy.q)]
	X[,T.buy.yq:=factor(T.buy.y):factor(T.buy.q)]

	# create duration bins
	X[,duration:=as.numeric(duration)]

	save(X,file="housing.RData")
}
