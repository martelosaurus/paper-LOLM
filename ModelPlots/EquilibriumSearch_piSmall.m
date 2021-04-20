close all
clear all


% Exogenous parameters 
lambda=.5;
Y=1;
Q = .7;
pi = .1;
r=.5;
c=.1;

% Additional notation
mur = r/(r+pi);
mupi = pi/(r+pi);
vH = lambda*Y/r;
kappa = r*c/(lambda*Y);

% Time
dt = .002;
Tmax = 10;
tgrid = 0:dt:Tmax;
Nt = length(tgrid);

% Owner's belief absent payoff breakthrough
g = Q.*exp(-lambda.*tgrid)./(Q.*exp(-lambda.*tgrid)+1-Q);

% Terminal conditions for S and q
STL = mur*c;
qTL = 1;


ST = zeros(Nt);
qT = zeros(Nt);

for i=1:Nt
    
    S = nan(1,Nt);
    q = nan(1,Nt);
   
    Ts=tgrid(i)
       
    for t=Nt+1-i:Nt
        
        if tgrid(Nt+1-t)>Ts
            S(Nt+1-t) = nan;
            q(Nt+1-t) = nan;
        elseif tgrid(Nt+1-t)==Ts
            S(Nt+1-t) = STL;
            q(Nt+1-t) = qTL;
        else
            S(Nt+1-t) = S(Nt+2-t) - dt*((r+g(Nt+2-t)*lambda+pi)*S(Nt+2-t)-(1-g(Nt+2-t))*lambda*Y);
            q(Nt+1-t) = q(Nt+2-t) - dt*(r*(q(Nt+2-t)-kappa-g(Nt+2-t))-lambda/vH*g(Nt+2-t)*S(Nt+2-t));

        end
        
        ST(i,:)=S;
        qT(i,:)=q;

    end
    
end



% Find T0 that(T) for T>T_0

for i=1:Nt
    
     if isempty(find(qT(i,:)<Q,1,'first'))
            
            thatT(i) = nan;
        
        else
            
            thatT(i) = tgrid(find(qT(i,:)<Q,1,'first'));
            
     end
        
end

indT0 = find(thatT>=0,1,'first');
T0 = tgrid(indT0);


figure; plot(tgrid,ST(1:100:Nt,:));
figure; plot(tgrid,qT(1:100:Nt,:),tgrid,Q*ones(1,Nt));
figure; plot(tgrid,thatT);

ThetaT = zeros(Nt);
DeltaT = zeros(Nt);

for i=indT0:Nt
    
    tgrid(i)
    
    Theta = nan(1,Nt);
    Delta = nan(1,Nt);
    
    ts=thatT(i);
    
    for t=1:i
        
        if tgrid(t)<=ts
            Theta(t) = exp(lambda*tgrid(t))-1;
            Delta(t) = 1;
        else
            Theta(t) = Theta(t-1) + dt*(lambda*Theta(t-1)+lambda*Delta(t-1));
            Delta(t) = Delta(t-1) + dt*(pi*Delta(t-1)-pi*g(t-1)*(1-qT(i,t-1))/(qT(i,t-1)-g(t-1))*Theta(t-1));
        end
        
        ThetaT(i,:) = Theta;
        DeltaT(i,:) = Delta;
        
    end
    
end

figure; plot(tgrid,DeltaT(1:100:Nt,:));

eqmCross = nan(1,Nt);

for i=indT0:Nt
    
    eqmCross(i) = DeltaT(i,i);
    
end

figure; plot(tgrid,eqmCross,tgrid,zeros(1,Nt));


% eqm values %

eqmInd = find(eqmCross<=0,1,'first');
TL = tgrid(eqmInd)
thatL = thatT(eqmInd)


% Now construct plots

% Variables needed for figure 4a, price, VL, VH

for t=1:Nt
    
    if tgrid(t)<=thatL
        
        qeqm(t)=Q;
        
    elseif tgrid(t)>=TL
        
        qeqm(t)=1;
        
    else
        
        qeqm(t)=qT(eqmInd,t);
        
    end
    
end

peqm = qeqm*lambda*Y/r-c;

VH=nan(1,Nt);

for t=1:Nt
        
        if tgrid(Nt+1-t)>=TL
            VH(Nt+1-t) =mur*vH+mupi*(vH-c);
        else
            VH(Nt+1-t) = VH(Nt+2-t) - dt*((r+pi)*VH(Nt+2-t)-lambda*Y-pi*peqm(Nt+2-t));
        end
        
end

VL = VH-ST(eqmInd,:);

figure; plot(tgrid,peqm,tgrid,VL,tgrid,VH); %figure 4a

% Variables needed for figure 4b, Gamma_L_prime

GammaL=nan(1,Nt);
GammaL(1:eqmInd) = 1-DeltaT(eqmInd,1:eqmInd);
GammaL(eqmInd+1:end) = 1;

GammaL_prime = zeros(1,Nt);
GammaL_prime(1:Nt-1) = diff(GammaL)/dt;
GammaL_prime(eqmInd)=0; %This needs to be fixed due to numerical error. If grid space is fine enough, this step can be ignored.

figure; plot(tgrid,GammaL)
figure; plot(tgrid,GammaL_prime) %figure 4b


% Variables needed for figures 5a and 5b, price, Strategic trade, Liquidity
% trade, total trade.

figure; plot(tgrid, peqm) %figure 5a

Lambda = nan(1,Nt);
Lambda(1:eqmInd) = exp(-lambda*tgrid(1:eqmInd)).*ThetaT(eqmInd,1:eqmInd);
Lambda(eqmInd+1:end) = Lambda(eqmInd);
    
strat = exp(-pi*tgrid).*(Q*exp(-lambda*tgrid)+1-Q).*GammaL_prime;
liq = pi*exp(-pi*tgrid).*(Q*Lambda+(Q*exp(-lambda*tgrid)+1-Q).*(1-GammaL));
tot = strat+liq;

plot(tgrid,strat,tgrid,liq,tgrid,tot) %figure 5b


