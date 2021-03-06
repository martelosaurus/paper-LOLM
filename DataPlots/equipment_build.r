library(data.table) 

if (is.element("equipment.RData",list.files())) {
    load("equipment.RData")
} else {

    # load
	load("equipment_raw.RData")

    # clean-up
    X=subset(X,!is.na(year_built)&!is.na(start_date))
    X[,date := as.Date(as.character(start_date), format = "%Y%m%d")]

    # calculate year sold and age
    X[,year_sold := year(date)]
    X[,quarter_sold := quarter(date)]
    X[,age := year_sold-year_built]
    X=subset(X,age>=0)

    # product id
    X = X[!serial_number==""]
    X[,modelid:=.GRP, by=.(manufacturer, model, year_built)]
    X[,pid:=.GRP, by=.(manufacturer, model, year_built, serial_number)]

    # calculate repeat transaction return
    setkey(X,pid,date)
    X[,lag_price:=shift(auction_price,type="lag"),by=pid]
    X[,lag_date:=shift(date,type="lag"),by=pid]    
    X[,year_bought := year(lag_date)]
    X[,quarter_bought :=quarter(lag_date)]
    X[,lag_age := year_bought-year_built]
    X[,lag_condition:=shift(condition,type="lag"),by=pid]
    X=subset(X,!is.na(lag_price))

    # calculate duration and log return
    setkey(X, modelid)
    X[,duration := as.numeric(date-lag_date)/365]    
    X[,logret:=log(auction_price/lag_price)]

    # final cuts
    X=subset(X,country_code=="US")
    X=subset(X,duration>0)
    X[,n.sales:=.N,by=.(modelid)]
    X=subset(X,n.sales>1)

    # drop
    save(X,file="equipment.RData")
}
