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
