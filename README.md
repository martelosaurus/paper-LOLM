# Learning by Owning in a Lemons Market

Forthcoming at the  *Journal of Finance*. Most of this code was written by or in collaboration with [Brian Waters](https://sites.google.com/site/briantwaters).

## Empirical work
Written in R. Requires `data.table` and `zoo`. For figures...

```R
source("driver.r")
# housing: figures
source("housing_build.r")
duration.breaks=seq(1/365,15+1/365,.25)
estimator(c("t.purchase.yq","T.purchase.yq"),duration.breaks,"housing",X)
# venture capital: figures
source("venture_capital_build.r")
duration.breaks=seq(.25,2.5,.125)
estimator(c(),duration.breaks,"venture_capital",X)
# equipment: figures 
source("equipment_build.r")
duration.breaks=seq(1/365,10+1/365,.25)
estimator(c("lag_age","age"),duration.breaks,"equipment",X)
```

## Numerical work
Written in Python. Requires `numpy`, `scipy`, and `matplotlib`. The module is `pgn.py` (`p`erfect `g`ood `n`ews). The `Equilibrium` object has two methods, `plot_val`, which plots values and prices, and `plot_pdf`, which plots probability densities. For figures...

```Python
from pgn import Equilibrium
# high liquidity
L_liq = Equilibrium(b=.1,c=.1,l=.5,r=.5,Q=.7,Y=1.) 
L_liq.plot_val(full=True)	# figure 4(a): price, L-value, H-value
L_liq.plot_pdf()	# figure 4(b): strategic
L_liq.plot_val()	# figure 5(a): price
L_liq.plot_pdf(full=True)	# figure 5(b): strategic, liquidity, total
# low liquidity
H_liq = Equilibrium(b=.9,c=.2,l=.5,r=.5,Q=.7,Y=1.) 
H_liq.plot_val(full=True)	# figure 6(a): price, L-value, H-value
H_liq.plot_pdf(full=True)	# figure 6(b): strategic, liquidity, total
```
