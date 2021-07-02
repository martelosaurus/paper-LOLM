source("main.r") # loads estimator function
# housing: 
#    figure 1(a) "housing_resrets.pdf"
#    figure 1(b) "housing_hist.pdf"
#    figure 7(a) "housing_rawrets.pdf"
#    figure 7(b) "housing_rotrets.pdf"
source("housing_build.r") # loads data.table X
duration_breaks=seq(1/365,15+1/365,.25)
estimator(c("t.buy.yq","T.buy.yq"),duration_breaks,"housing",X)
# venture capital: 
#    figure 2(a) "venture_capital_rawrets.pdf"
#	 figure 2(b) "venture_capital_hist.pdf"
source("venture_capital_build.r") # loads data.table X
duration_breaks=seq(.25,2.5,.125)
estimator(c(),duration_breaks,"venture_capital",X,smpar=1.)
# equipment: 
#    figure 3(a) "equipment_resrets.pdf"
#    figure 3(b) "equipment_hist.pdf"
#    figure 8(a) "equipment_rawrets.pdf"
#    figure 8(b) "equipment_rotrets.pdf"
source("equipment_build.r") # loads data.table X
duration_breaks=seq(1/365,10+1/365,.25)
estimator(c("lag_age","age"),duration_breaks,"equipment",X)
