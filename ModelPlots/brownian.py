# ------------------------------------------------------------------------------
import numpy as np
from matplotlib import pyplot as plt
from thresh2belief import thresh2belief

# MODEL PARAMETERS
H   = 1 		# high type drift 
L   = 0 		# low type drift
sig = 1 		# volatility
phi = (H-L)/sig # signal to noise ration
pie = 0.4 		# intensity of liquiidity sale 
r   = 0.5 		# discount rate r*dt
c   = .1 		# transaction cost at time of sale
T   = 20 		# length of time
x0  = .8 		# initial belief

# CODE PARAMETERS 
N = 20000	# size of time vector
M = 5000 	# size of belief vector
K = 50
S = 2000	# number of simulations
a = .00001

# AUXILIARY FUNCTIONS
interp_fun = lambda xi,yi,x: np.polyval(np.polyfit(xi,yi,1),x)

# MESHSIZE AND GRID
dx = 1/(1+M)
dt = T/(1+N)
x = np.linspace(0,1,M+1) 
t = np.linspace(0,T,N+1)

# GUESSES
_bB	= x0*np.ones(N+1)
p	= (x0*H+(1-x0)*L-c)*np.ones(N+1) 

# BOUNDARY ITERATION
for k in range(1,K):

	# INITIALIZE VALUE FUNCTION, BELIEF BOUNDARY, VALUE AT BELIEF BOUNDARY
	V 	= np.zeros((M+1, N+1)) 	# value function: row each belief; col each time
	bB 	= np.zeros(N+1) 		# belief boundary
	vB 	= np.zeros(N+1) 		# value function at boundary belief

	# TERMINAL VALUE
	v1 	= (x*r*H+(1-x)*r*L+pie*p[-1])/(r+pie) 	# keep asset forever
	p1 	= p[-1]*np.ones(M+1) 					# choose the last price
	V[:,-1] = np.max([v1,p1],0) 				# terminal value

	# STEP BACK FROM TERMINAL TIME
	for n in range(0,N):

		# EXPECTED CONTINUATION VALUE
		Vup = interp_fun(x,V[:,-(n+1)],x+phi*x*(1-x)*np.sqrt(dt)) 
		Vdn = interp_fun(x,V[:,-(n+1)],x-phi*x*(1-x)*np.sqrt(dt))
		Vex = .5*Vup+.5*Vdn	
		
		# SELLER OPTIMALLY CHOOSES WHETHER TO SELL OR CONTINUE
		v1 = dt*(x*r*H+(1-x)*r*L)				# expected drift
		v2 = pie*dt*p[-n]*np.ones(M+1)			# liquidity sale
		v3 = (1-pie*dt)*(1-r*dt)*Vex			# continuation value
		vv = v1+v2+v3
		vval = np.max([p[-n]*np.ones(M+1),v1+v2+v3],0)

		# INDICES OF X VALUES AT WHICH YOU CONTINUE; A IS SMOOTHING ADJUSTMENT
		contV = (vval<p[-n]*np.ones(M+1)+a) 
		
		# BOUNDARY
		if contV[0]==0:
			bB[-1-n] = x[1] # belief boundary
			vB[-1-n] = vval[1] # value function at boundary belief
		elif contV[M]==1:
			bB[-1-n] = x[M+1] # belief boundary
			vB[-1-n] = vval[M+1] # value function at boundary belief
		else:
			# belief boundary
			last = np.max(np.where(contV))
			bB[-1-n] = x[last] # 'last'
			# value function at boundary belief
			vB[-1-n] = vval[last] # 'last'
		
		# update value
		V[:,-n] = vval 

	# update boundary
	bB[-1] = bB[-2]
	bB_guess = (.2*bB+.8*bB_guess)

	# given boundary, compute strategies
	bb,Gam_H,gam_H,Gam_L,gam_L = thresh2belief(t,bB_guess,S,x0,pie,H,L,sig) 

	# construct price from buyers' beliefs
	p = bb*H + (1-bb)*L - c 
	p[-1] = H-c

# compute pdf and cdf
pdf = np.exp(-pie*t)*(x0*(gam_H+(1-Gam_H)*pie)+(1-x0)*(gam_L+(1-Gam_L)*pie)) 
cdf = 1-np.exp(-pie*t) + np.exp(-pie*t)*(x0*Gam_H+(1-x0)*Gam_L)
cdf2 = (pdf*dt).cumsum() # confirmation
haz = pdf/(1-cdf)

# split pdf
pdfLiquidity = np.exp(-pie*t)*(x0*gam_H+(1-x0)*gam_L)
pdfStrategic = np.exp(-pie*t)*(x0*(1-Gam_H)+(1-x0)*(1-Gam_L))*pie

# plot
plt.plot(t,[vB,p])
plt.plot(t,gam_H,t,gam_L,t,x0*gam_H+(1-x0)*gam_L)
