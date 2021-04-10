import numpy as np
from scipy import stats

def thresh2belief(tt,st,ns,b0,lam0,mu_H,mu_L,sig):
    """
    thresh2price maps a selling threshold to buyers' belief. It assumes 
    that sellers' beliefs converge in finite time (t=Tf): sellers' private 
    signals follow a Brownian bridge.

    tt : vector 
        A vector of equi-spaced times, with t(0)=0 and t(end)=Tf, where
        Tf is the final time.
    st : vector
        A vector of selling thresholds
    ns : integer
        The number of times to simulate the belief process
    r  : float
        Agents' discount rate
    mu_H : float
        Flow utility from an H-type asset
    mu_L : float
        Flow utility from an L-type asset
    sig  : float
        Signal volatility
    bb : vector
        Buyers' belief
    """

    # new parameters
    phi = (mu_H-mu_L)/sig
    mub = (mu_H+mu_L)/2

    # number of time steps
    nt = len(tt)
    dt = tt[-1]/(nt-1)
    
    # reshape input
    tt = np.tile(tt,(nt,1))
    TT = np.tile(tt,(1,ns))
    st = np.tile(st,(nt,1))
    BB = b0*ones(ns,nt)
    
    # each row is a separate simulation
    st[-1] = st[-2] 		# this comes out as NaN for some reason
    ST = repmat(st,ns,1) 	# tile the threshold vector
    
    def Gamma(mu):
        
        # stuff
        BM = (np.sqrt(dt)*np.random.rand(ns,nt)).cumsum(1)
        CF = mu*TT+sig*BM 
        
        # beliefs
        for j in range(1,(nt-1)):
            BB[:,j+1] = (BB[:,j]+BB[:,j]*(1-BB[:,j])*(phi/sig)*
                (CF[:,j+1]-CF[:,j]-(BB[:,j]*mu_H+(1-BB[:,j])*mu_L)*dt))
            
        # stopping times
        TEMP = (BB>=ST).cumprod(1)
        stops = tt[sum(TEMP,2)]
        stops = stops[stops<tt[-1]]
        
        # CDF, PDF, and hazard rate
        Gam	= 1-mean(TEMP,1)
        kde = stats.gaussian_kde(stops)
		gam = kde(tt)*Gam[-1]
        
        return Gam,gam

    # distributions for H and L
    Gam_H, gam_H = Gamma(mu_H)
    Gam_L, gam_L = Gamma(mu_L)

    # beliefs
    bb = (b0*(gam_H+(1-Gam_H)*lam0)/
        (b0*(gam_H+(1-Gam_H)*lam0)+(1-b0)*(gam_L+(1-Gam_L)*lam0)))
  
    return bb,Gam_H,gam_H,Gam_L,gam_L
