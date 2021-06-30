# Learning by Owning in a Lemons Market

Forthcoming at the  *Journal of Finance*. Most of this code was written by, or in collaboration with, [Brian Waters](https://sites.google.com/site/briantwaters).

## Empirical work
Written in R. Requires `data.table`, `ggplot2`, `lfe` and `zoo`. Pseudo-data provided in DataPlots/pseudo-data. For figures, run

```R
source("driver.r")
# housing: figures 1(a) "housing_resrets.pdf", 1(b) "housing_hist.pdf", 7(a) "housing_rawrets.pdf", 7(b) "housing_rotrets.pdf"
source("housing_build.r")
duration.breaks=seq(1/365,15+1/365,.25)
estimator(c("t.purchase.yq","T.purchase.yq"),duration.breaks,"housing",X)
# venture capital: figures 2(a) "venture_capital_rawrets.pdf", 2(b) "venture_capital_hist.pdf"
source("venture_capital_build.r")
duration.breaks=seq(.25,2.5,.125)
estimator(c(),duration.breaks,"venture_capital",X)
# equipment: figures 3(a) "equipment_resrets.pdf", 3(b) "equipment_hist.pdf", 8(a) "equipment_rawrets.pdf", 8(b) "equipment_rotrets.pdf"
source("equipment_build.r")
duration.breaks=seq(1/365,10+1/365,.25)
estimator(c("lag_age","age"),duration.breaks,"equipment",X)
```
Ensure that all scripts and data live in the same directory.

## Numerical work
Written in Python. Requires `numpy`, `scipy`, and `matplotlib`. The module is `perfect_good_news.py`. The `Equilibrium` object has two methods, `plot_val`, which plots values and prices, and `plot_pdf`, which plots probability densities. For figures, run

```Python
from perfect_good_news import Equilibrium
# high liquidity
L_liq = Equilibrium(b=.1,c=.1,l=.5,r=.5,Q=.7,Y=1.) 
L_liq.plot_val(full=True) # figure 4(a): price, L-value, H-value
L_liq.plot_pdf(leg=False) # figure 4(b): strategic
L_liq.plot_val(leg=False) # figure 5(a): price
L_liq.plot_pdf(full=True) # figure 5(b): strategic, liquidity, total
# low liquidity
H_liq = Equilibrium(b=.9,c=.2,l=.5,r=.5,Q=.7,Y=1.) 
H_liq.plot_val(full=True) # figure 6(a): price, L-value, H-value
H_liq.plot_pdf(full=True) # figure 6(b): strategic, liquidity, total
```
