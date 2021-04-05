library(data.table)

# switch: if TRUE, then uses proprietary data; else uses dummy data
# WARNING: dummy data will NOT reproduce the figures in the manuscript
real = TRUE

if (FALSE) {
# equipment-------------------------------------------------------------------#
source("equipment_build.r")
duration.breaks=seq(1/365,10+1/365,.25)
estimator(c("lag_age","age"),duration.breaks,"equipment",X)
}


# venture capital ------------------------------------------------------------#
source("venture_capital_build.r")
duration.breaks=seq(.25,2.5,.125)
estimator(c(),duration.breaks,"venture_capital",X)

if (FALSE) {
# housing---------------------------------------------------------------------#
source("housing_build.r")
duration.breaks=seq(1/365,15+1/365,.25)
estimator(c("t.purchase.yq","T.purchase.yq"),duration.breaks,"housing",X)
}
