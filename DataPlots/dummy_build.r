library(data.table)

# ------------------------------------------------------------------------------
# COMMON PARAMETERS
date0 = as.Date('1990-01-01')
date1 = as.Date('2019-12-31')
dates = seq(date0,date1,1)

# ------------------------------------------------------------------------------
# HOUSING
#
# There are forty houses, each of which is sold three times.
X = data.table(
	salespriceamount=sample(seq(100000,999999,1),120,replace=TRUE),
	importparcelid=rep(sample(seq(1000,9999,1),40,replace=TRUE),3),
	sqft=rep(sample(seq(1000,9999,1),40,replace=TRUE),3),
	documentdate=sample(dates,120,replace=TRUE)
)
write.csv(X,file='housing.csv')

# ------------------------------------------------------------------------------
# EQUIPMENT
#
# There are two manufactures, X and Y. X has models A and B; Y has models C and 
# D. There are two pieces of each model, for a total of eight pieces of 
# equipment.
X = data.table(
	manufacturer=rep(paste("Company",c("X","Y")),each=60),
	model=rep(paste("Model",c("A","B","C","D"),sep="-"),each=30),
	year_built=rep(sample(seq(1980,1989,1),8,replace=TRUE),each=15),
	serial_number=rep(sample(seq(100000,999999,1),8,replace=TRUE),each=15),
	date=sample(dates,120,replace=TRUE),
	auction_price=sample(seq(10000,99999,1),120,replace=TRUE),
	condition=rep("U",120),
	country_code=rep("US",120)
)
X[,start_date:=format(date,"%Y%m%d")]
write.csv(X,file='equipment.csv')

# ------------------------------------------------------------------------------
# VENTURE CAPITAL
# There are two companies, X and Y. There are two funds, A and B which invest in
# each company in each of 30 rounds.
X = data.table(
	investment.date=rep(sort(sample(dates,60,replace=TRUE)),each=2),
	company.id=rep(paste("Company",c("X","Y")),each=60),
	firm.name=rep(paste("Fund",c("A","B")),60),
	round.number=rep(rep(seq(1,30,1),each=2),2),
	amount=sample(seq(1,20,1),120,replace=TRUE),
	valuation=sample(seq(1,20,1),120,replace=TRUE),
	equity.invested=sample(seq(1,20,1),120,replace=TRUE)
)
# In this example, all investments are reported (not true in reality)
if (FALSE) {
X[,equity.invested:=cumsum(amount),by=.(company.id)]
X[,equity.invested:=max(equity.invested),by=.(investment.date,company.id,round.number)]
}
#write.csv(X,file='venture_capital.csv')
write.csv(X,file='venture_capital_dats/dummy.csv')
