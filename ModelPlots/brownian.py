import numpy as np
from matplotlib import pyplot as plt
from thresh2price import thresh2price

# model parameters
H 	= 1 # high type drift 
L 	= 0 # low type drift
sig = 1 # volatility
phi = (H-L)/sig # signal to noise ration
pie = 0.4 # intensity of liquiidity sale 
r 	= 0.5 # discount rate r*dt
c 	= .1 # transaction cost at time of sale
T 	= 20 # length of time
x0 	= .8 # initial belief
# flow value multiplied by r below so price need not be divided by r

# code parameters 
N 	= 20000 # size of time vector
M 	= 5000 # size of belief vector
MAX = 50
tol = .00001

# auxiliary functions
interpFun = @(x,y,xi) interp1(x,y,xi,'linear','extrap') 

# meshsize and grid
dx = 1/(1+M)
dt = T/(1+N)
xgrid = np.linspace(0,1,M+1) 
tgrid = np.linspace(0,T,N+1)

# guesses
lBound_guess = x0*ones(1,N+1)
p = (x0*H+(1-x0)*L-c)*ones(1,N+1) 

# main loop
for loop in range(1,MAX):

	Vmat = np.empty(M+1, N+1) # value function for each belief at each time 

	lBound = np.empty(1, N+1) # belief boundary
	vBound = np.empty(1, N+1) # value function at boundary belief

	# assumption is game -1s, so choose either last price or keep asset forever
	Vmat[:,-1] = max((xgrid*r*H+(1-xgrid)*r*L+pie*p[-1])/(r+pie),p[-1]) 

	# stepIdx = 1 # stepIdx = 2 # stepIdx = 3 # stepIdx = floor(N/4) 
	for stepIdx in range(1,N):
		
		upval = xgrid+phi*1*xgrid*(1-xgrid)*sqrt(dt) # up part of belief process
		dnval = xgrid-phi*1*xgrid*(1-xgrid)*sqrt(dt) # dn part of belief process

		# interpolate value if falls between discrete beliefs 
		VupContval = interpFun(xgrid, Vmat[:,-1-stepIdx+1], upval) 
		VdnContval = interpFun(xgrid, Vmat[:,-1-stepIdx+1], dnval)
		
		V_cont = (VupContval+VdnContval)/2 
	   
		# seller optimally chooses whether to sell or continue
		vval = max( [ (p(-1-stepIdx))*ones(M+1,1), dt*(xgrid*r*H+(1-xgrid)*r*L)+ pie*dt*(p(-1-stepIdx+1))*ones(M+1,1) + (1-pie*dt)*(1-r*dt)*V_cont], [], 2) 
		# indices of the x values at which you continue (don't sell) - adjust by .001 to smooth over indifference
		contV = (vval < (p(-1-stepIdx))*ones(M+1,1)+tol) 
		
		# fix
		if contV[1]==0
			lBound[-1-stepIdx] = xgrid[1] # belief boundary
			vBound[-1-stepIdx] = vval[1] # value function at boundary belief
		elif contV(M+1)==1
			lBound[-1-stepIdx] = xgrid[M+1] # belief boundary
			vBound[-1-stepIdx] = vval[M+1] # value function at boundary belief
		else
			# belief boundary
			lBound[-1-stepIdx] = xgrid[find(contV>0,1,'last')] 
			# value function at boundary belief
			vBound[-1-stepIdx] = vval[find(contV>0,1,'last' )] 
		
		Vmat[:,-1-stepIdx] = vval 

	lBound[-1]=lBound[-1-1]
	lBound_guess = (.2*lBound+.8*lBound_guess)

	bb,Gam_H,gam_H,lam_H,Gam_L,gam_L,lam_L = thresh2belief(tgrid,lBound_guess,20000,x0,pie,H,L,sig) 

	#bb = x0*(gam_H+(1-Gam_H)*pie)./(x0*(gam_H+(1-Gam_H)*pie)+(1-x0)*(gam_L+(1-Gam_L)*pie)) #construct buyers' beliefs

	p = bb*H + (1-bb)*L - c #construct price from buyers' beliefs
	p[-1]=H-c

# compute pdf and cdf
pdf = np.exp(-pie*tgrid)*(x0*(gam_H+(1-Gam_H)*pie)+(1-x0)*(gam_L+(1-Gam_L)*pie)) #ex ante probability of sale at t
cdf = 1-np.exp(-pie*tgrid) + np.exp(-pie*tgrid)*(x0*Gam_H+(1-x0)*Gam_L)
cdf2 = (pdf*dt).cumsum() #to confirm that pdf and cdf seem correct - should be case that cdf=cdf2
haz = pdf./(1-cdf)

# plot
plot(tgrid,[vBound(:),p(:)])
plot(xgrid,Vmat[:,1000],xgrid,p[1000]*ones(1,M+1))
pdfLiq = np.exp(-pie*tgrid)*(x0*gam_H+(1-x0)*gam_L)
pdfStrat = np.exp(-pie*tgrid)*(x0*(1-Gam_H)+(1-x0)*(1-Gam_L))*pie
plot(tgrid,gam_H,tgrid,gam_L,tgrid,x0*gam_H+(1-x0)*gam_L)
