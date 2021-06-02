options(stringsAsFactors=FALSE)
library(data.table)
# ------------------------------------------------------------------------------
# VENTURE CAPITAL
X = list()
for(fn in list.files(pattern="Fund_round_investment")) {

	dt_fri = data.table(read.csv(fn,stringsAsFactors=FALSE))
  
	setnames(dt_fri, colnames(dt_fri), tolower(colnames(dt_fri)))
  
	cnames_to_rename=c(
		'sic.code', 
		'naic.code', 
		'equity.amount.disclosed..usd.mil.', 
		'valuation.at.transaction.date..usd.mil.', 
		'no..of.funds.at.investment.date', 
		'fund.known.equity.invested.in.company.at.investment.date..usd.mil.')
	setnames(dt_fri, cnames_to_rename, c('sic', 'naics', 'amount', 'valuation',
					   'n.funds', 'equity.invested'))
  
	dt_fri[, investment.date := as.Date(investment.date, format = "%m/%d/%Y")]
  
	X=c(X,list(dt_fri))
}
X=rbindlist(X)
setkey(X,company.id,round.number)
write.csv(X,file="venture_capital_raw.csv",row.names=FALSE)

if (FALSE) {
# ------------------------------------------------------------------------------
# EQUIPMENT
X=data.table(read.dta('auction_new.dta'))
X=X[,.(
	year_built,
	start_date,
	serial_number,
	manufacturer,
	model,
	auction_price,
	condition,
	country_code)]
write.csv(X,file="equipment_raw.csv",row.names=FALSE)

# ------------------------------------------------------------------------------
# HOUSING
if (!is.element("ztrax.RData",list.files())) {
	X=data.table(read.dta("repeat_transactions.dta"))
	X=X[,.(salespriceamount,
			importparcelid,
			sqft,
			documentdate)]
	save(X,file="ztrax.RData")
}
}
