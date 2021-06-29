# FIXME cache with lru_cache
import numpy as np
import matplotlib.pyplot as plt
from scipy.integrate import quad, fixed_quad, solve_ivp
from scipy.optimize import root_scalar, root, minimize_scalar

#------------------------------------------------------------------------------#
# parameter checks

class Equilibrium:

    def __init__(self,b=.1,c=.1,l=.5,r=.5,Q=.7,Y=1.):
    #def __init__(self,b=.9,c=.2,l=.5,r=.5,Q=.7,Y=1.):

        # tolerance (see Te for usage)
        tol = 1.e-5

        # plotting
        N = 200

        # synthetic parameters
        vH = l*Y/r
        C1 = r*c/(r+b)
        C2 = l*Y/(r+b)

		# terminal conditions
        VL1 = vH-c 
        VH1 = vH-b*c/(r+b)

        # paramter checks
        if c>Q*l*Y/r or l>r+b:
            raise Exception('bad parameter regime')

        # 
        D = lambda t: Q*np.exp(-l*t)+1.-Q     # auxiliary function
        g = lambda t: Q*np.exp(-l*t)/D(t)     # owner beliefs
        a = lambda t: b*np.exp(-b*t)         # PDF of liquidity sale

        #----------------------------------------------------------------------#
        # special functions 

        @np.vectorize
        def S(t,T): 
            """surplus"""
            if t <= T:
                Z = np.exp(-(r+b)*(T-t))
                return ((1.-g(t))/(1.-g(T)))*(C1*Z+(1.-g(T))*C2*(1.-Z))
            else:
                return np.nan

        @np.vectorize
        def VL(t,T): 
            """L-value"""
            qo = fixed_quad(lambda s: g(s)*(Y+S(s,T))*np.exp(-r*(s-t)),t,T)
            return VL1*np.exp(-r*(T-t))+l*qo[0]

        def VH(t,T):
            """H-value"""
            return VL(t,T)+S(t,T)

        @np.vectorize
        def q(t,T): 
            """market beliefs"""
            if t <= T:
                return r*(VL(t,T)+c)/(l*Y)
            else:
                return np.nan

        def H(t,T): 
            """H-function"""
            return g(t)*(1-q(t,T))/(q(t,T)-g(t))

        #----------------------------------------------------------------------#
        # special times 

        def _T0_fun(x): 
            T, t = x
            return np.array([VL(t,T)-(Q*l*Y/r-c),r*VL(t,T)-l*g(t)*(Y+S(t,T))])

        sol = root(_T0_fun,np.array([2.,1.]))
        T0, t0 = sol.x

        def _T1_fun(T): 
            return q(0.,T)-Q
        sol = root_scalar(_T1_fun,x0=T0,x1=2*T0)
        if np.isnan(sol.root):
            T1 = np.inf
        else:
            T1 = sol.root

        def t_hat(T): 
            """t-hat"""
            if T>T0:
                if T<T1:
                    return root_scalar(lambda t: q(t,T)-Q,bracket=(0,t0)).root
                else:
                    return np.nan
            else:
                return np.nan

        def t_til(T):
            """t-tilde"""
            return minimize_scalar(lambda t: VL(t,T),(t_hat(T),T)).x

        #----------------------------------------------------------------------#
        # Theta-Delta

        def f(t,y,T): 
            """RHS for Theta-Delta ODE (y[0]=Theta, y[1]=Delta)"""
            y_t = np.zeros(y.shape)
            y_t[0,] = l*y[0,]+l*y[1,]
            y_t[1,] = -b*H(t,T)*y[0,]+b*y[1,]
            return y_t

        def y0(T):
            """IC for Theta-Delta ODE (y[0]=Theta, y[1]=Delta)"""
            return np.array([np.exp(l*t_hat(T))-1.,1.]) 

        def _Delta(T):
            """solves for Delta at T"""
            sol = solve_ivp(lambda s,y: f(s,y,T),(t_hat(T),T),y0(T))
            return sol.y[1][-1]

        #----------------------------------------------------------------------#
        # equilibrium 

        if np.isinf(T1):
            Te = root_scalar(_Delta,x0=1.5*T0,x1=2.*T0).root
        else:
            Te = root_scalar(_Delta,bracket=((1.+tol)*T0,(1.-tol)*T1)).root

        t_hat_e = t_hat(Te) # equilibrium t_hat
        t_til_e = t_til(Te) # equilibrium t_tilde

        #----------------------------------------------------------------------#
        # plot equilibrium

        # time vectors for sections 0,1,2
        t0v = np.linspace(.5*t_hat_e,t_hat_e,N) 
        t1v = np.linspace(t_hat_e,Te,N) 
        t2v = np.linspace(Te,1.5*Te,N) 

        # zeros and ones
        zv, ov = np.zeros(N), np.ones(N)

        # time and liquidity density
        self.tv = np.hstack((t0v,t1v,t2v))
        self.av = a(self.tv)

        # solve for `q` on mid-section
        qq1v = q(t1v,Te)

        # solve for `Theta` and `Delta` on mid-section
        sol = solve_ivp(lambda s,y: f(s,y,Te),(t_hat_e,Te),y0(Te),t_eval=t1v)
        Theta, Delta = sol.y  
        Lambda = Theta*np.exp(-l*t1v)
        _ , Delta_t = f(t1v,sol.y,Te)    # derivatives
        Omega_t = np.exp(-b*t1v)*((Q*Lambda+D(t1v)*Delta)*b-D(t1v)*Delta_t)

        # stack price, L-value, H-value vectors for plotting
        self.ppv = np.hstack((Q*vH*ov-c,vH*qq1v-c,vH*ov-c))  # price
        self.VLv = np.hstack((VL(t0v,Te),vH*qq1v-c,VL1*ov)) # L-value
        self.VHv = np.hstack((VH(t0v,Te),VH(t1v,Te),VH1*ov)) # H-value 

        # stack for plotting
        Lambda_v = np.hstack((1.-np.exp(-l*t0v),Lambda,Lambda[-1]*ov))
        Delta_v    = np.hstack((ov,Delta,zv))
        self.Gamma_tv = np.hstack((zv,-Delta_t,zv))                
        Omega_tv = np.hstack((a(t0v),Omega_t,a(t2v)))        
        
        # prob not sold (str)ategically, for (liq)uidity 
        pr_not_str = Q*Lambda_v+D(self.tv)*Delta_v
        pr_not_liq = D(self.tv)*np.exp(-b*self.tv)

        # unconditional strategic, liquidity sale densities
        self.strategic = pr_not_liq*self.Gamma_tv
        self.liquidity = pr_not_str*self.av

        # x-ticks and their labels
        self.ticks = [t_hat_e,t_til_e,Te]
        self.tlabs = ["$\\hat{t}_L$","$\\tilde{t}$","$T_L$"]

    def plot_val(self,full=False,leg=True):
        """plot price/belief/values"""
        plt.xlabel("Time to Sale")
        plt.ylabel("Value")
        plt.xticks(self.ticks,self.tlabs)
        plt.yticks([],[])
        plt.plot(self.tv,self.ppv,'-k')
        if full:
            plt.plot(self.tv,self.VLv,'--k')
            plt.plot(self.tv,self.VHv,'-.k')
        if leg:
            plt.legend(['$p$','$V_L$','$V_H$'],frameon=False)
        plt.show()

    def plot_pdf(self,full=False,leg=True):
        """plot probability of sale densities"""
        plt.xlabel("Time to Sale")
        plt.ylabel("Probability Density")
        plt.xticks(self.ticks,self.tlabs)
        plt.yticks([],[])
        if full:
            plt.plot(self.tv,self.strategic,'--k')
            plt.plot(self.tv,self.liquidity,'-.k')
            plt.plot(self.tv,self.strategic+self.liquidity,'-k')
        else:
            plt.plot(self.tv,self.Gamma_tv,'-k')
        if leg:
            plt.legend(['Strategic','Liquidity','Total'],frameon=False)
        plt.show()
