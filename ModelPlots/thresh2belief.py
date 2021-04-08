def thresh2belief(tt,st,ns,b0,lam0,mu_H,mu_L,sig)
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
	   
	Notes
	----------
	I return the buyers' belief rather than the price.
	"""

    # new parameters
    phi = (mu_H-mu_L)/sig;
    mub = (mu_H+mu_L)/2;

    # number of time steps
    nt = length(tt);
    dt = tt(nt)/(nt-1);
    
    # reshape input
    tt = reshape(tt,1,nt);
    TT = repmat(tt,ns,1); 
    st = reshape(st,1,nt);
    BB = b0*ones(ns,nt);
    
    # each row is a separate simulationclear all;
    st(end) = st(end-1); # this comes out as NaN for some reason
    ST = repmat(st,ns,1); # tile the threshold vector
    
    def Gamma(mu)
        
        # stuff
        BM = sqrt(dt)*cumsum(randn(ns,nt),2);
        CF = mu*TT+sig*BM; 
        
        # beliefs
        for j = 1:(nt-1)
            BB(:,j+1) = BB(:,j)+BB(:,j).*(1-BB(:,j)).*(phi/sig)...
                .*(CF(:,j+1)-CF(:,j)-(BB(:,j)*mu_H+(1-BB(:,j))*mu_L)*dt);
        end
            
        # stopping times
        TEMP = cumprod(BB>=ST,2);
        stops = tt(sum(TEMP,2));
        stops = stops(stops<tt(end));
        
        # CDF, PDF, and hazard rate
        Gam = 1-mean(TEMP,1);
        gam = ksdensity(stops,tt);
        gam = gam*(Gam(end));
        lam = gam./(1-Gam);
        
		return [Gam,gam,lam]

    # distributions for H and L
    [Gam_H,gam_H,lam_H] = Gamma(mu_H);
    [Gam_L,gam_L,lam_L] = Gamma(mu_L);

    # beliefs
    bb = b0*(gam_H+(1-Gam_H)*lam0)...
        ./(b0*(gam_H+(1-Gam_H)*lam0)+(1-b0)*(gam_L+(1-Gam_L)*lam0));
  
	return [bb,Gam_H,gam_H,lam_H,Gam_L,gam_L,lam_L]

