import numpy as np
import matplotlib.pyplot as plt
from scipy.integrate import quad, fixed_quad, solve_ivp
from scipy.optimize import root_scalar, root, minimize_scalar

#-----------------------------------------------------------------------------#
# parameter checks

#plotting 
N = 200
npz = np.zeros(N)
npo = np.ones(N)
	
# low liquidity parameters
if True:
    b = .1 # \pi
    c = .1 
    l = .5 # \lambda 
    r = .5  
    Q = .7 
    Y = 1.

# high liquidity parameters
if False:
    b = .9
    c = .2
    l = .5
    r = .5
    Q = .7
    Y = 1.

opttol = 1.e-5

# synthetic parameters
vH = l*Y/r
C1 = r*c/(r+b)
C2 = l*Y/(r+b)

# terminal conditions
VL1 = l*Y/r-c 
VH1 = l*Y/r-r*c/(r+b)

# paramter checks
if c>Q*l*Y/r or l>r+b:
    raise Exception('bad parameter regime')

@np.vectorize
def _D(t): 
    """auxiliary function"""
    return Q*np.exp(-l*t)+1.-Q

@np.vectorize
def g(t): 
    """owner beliefs"""
    return Q*np.exp(-l*t)/_D(t)

#-----------------------------------------------------------------------------#
# values (analytical)

@np.vectorize 
def H(t): 
    """H-function"""
    return 2.*(1.-g(t))*l*Y/(r+b-l*(1.-2.*g(t)))

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

@np.vectorize
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

#-----------------------------------------------------------------------------#
# special times (T0, T1, t_hat, t_tilde)

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
    """\\hat{t}"""
    if T>T0:
        if T<T1:
            return root_scalar(lambda t: q(t,T)-Q,bracket=(0,t0)).root
        else:
            return np.nan
    else:
        return np.nan

def t_til(T):
    """\\tilde{t}"""
    return minimize_scalar(lambda t: VL(t,T),(t_hat(T),T)).x

#-----------------------------------------------------------------------------#
# Lambda-Delta
def f(t,y,T): 
    """RHS for Lambda-Delta ODE (y[0]=Lambda, y[1]=Delta)"""
    F = Q*(1.-q(t,T))/(q(t,T)*(1.-Q)-Q*np.exp(-l*t)*(1.-q(t,T)))
    y_prime = np.zeros(y.shape)
    y_prime[0] = l*np.exp(-l*t)*(1.-y[1])
    y_prime[1] = b*F*y[0]-b*(1.-y[1])
    return y_prime

@np.vectorize
def f_vec(t,y0,y1,T):
    """vectorized wrapper for f"""
    return f(t,np.array([y0,y1]),T)

def y0(T):
    """IC for Lambda-Delta ODE (y[0]=Lambda, y[1]=Delta)"""
    return np.array([1.-np.exp(-l*t_hat(T)),0.]) 

def Delta_T(T):
    """solves for Delta at T"""
    sol = solve_ivp(lambda s,y: f(s,y,T),(t_hat(T),T),y0(T))
    return sol.y[1][-1]

#-----------------------------------------------------------------------------#
# equilibrium T_L

if np.isinf(T1):
    T_eq = root_scalar(Delta_T,x0=1.5*T0,x1=2.*T0).root
else:
    T_eq = root_scalar(Delta_T,bracket=((1.+opttol)*T0,(1.-opttol)*T1)).root

t_hat_eq = t_hat(T_eq)
t_til_eq = t_til(T_eq)

#-----------------------------------------------------------------------------#
# plot equilibrium

# time vectors
t0_vec = np.linspace(0.,t_hat_eq,N) 
t1_vec = np.linspace(t_hat_eq,T_eq,N) 
t2_vec = np.linspace(T_eq,t_hat_eq+T_eq,N) 

# belief vectors
qG0_vec = Q*np.ones(N)
GG1_vec = np.zeros(N)
qq1_vec = np.zeros(N)
qG2_vec = np.ones(N)
ones    = np.ones(N)
zeros   = np.ones(N)

# t-vec
t_vec = np.hstack((t0_vec,t1_vec,t2_vec))

# solve for Lambda and Delta
sol = solve_ivp(lambda s,y: f(s,y,T_eq),(t_hat_eq,T_eq),y0(T_eq),t_eval=t1_vec)
Lambda_p, Delta_p = f_vec(sol.t,sol.y[0],sol.y[1],T_eq)
Omega_p = np.exp(-b*t1_vec)*((Q*Lambda+D(t1_vec)*Delta)*b-D(t1_vec)*Delta_p)

# stack vectors for plotting
qq1_vec = q(t1_vec,T_eq)
q_vec = np.hstack((Q*ones,qq1_vec,ones))
p_vec = vH*q_vec-c
VL_vec = np.hstack((VL(t0_vec,T_eq),vH*qq1_vec-c,vH*qG2_vec-c))
VH_vec = VH(t_vec,T_eq)

#-----------------------------------------------------------------------------#
# plot price/belief/values
plt.xlabel("Time to Sale")
plt.ylabel("Value")
plt.xticks([t_hat_eq,t_til_eq,T_eq],["$\\hat{t}$","$\\tilde{t}$","$T$"])
plt.yticks([],[])
plt.plot(t_vec,p_vec,'-k')
plt.plot(t_vec,VL_vec,'--k')
plt.plot(t_vec,VH_vec,'-.k')
plt.legend(['$p$','$V_L$','$V_H$'])
plt.show()

#-----------------------------------------------------------------------------#
# plot price/belief/values
plt.xlabel("Time to Sale")
plt.ylabel("Probability Density")
plt.xticks([t_hat_eq,t_til_eq,T_eq],["$\\hat{t}$","$\\tilde{t}$","$T$"])
plt.yticks([],[])
plt.plot(t_vec,-Delta_p,'--k')
plt.plot(t_vec,b*np.exp(-b*t_vec),'.-k')
plt.plot(t_vec,Omega_p,'-k')
plt.legend(['Strategic','Liquidity','Total'])
plt.show()
