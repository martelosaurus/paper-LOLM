close all
clear all

% Base Model Param: Y=1, c=.1, r=.5, pie=.1, lambda=.5, Q=.7;
% Param that change shape lambda=.5, Y=.5, c=.8, r=.2, pie=1.2, Q=.7;

lambda=.5;
Y=.5;
c=1;
r=.2;
pie = .1;
Q = .81;

Q > r*c/(lambda*Y)

% r*c/(lambda*Y) > Q*(pie/(r+pie))*(lambda/(r+lambda)) 

pie < (r^2*c)/(lambda*Y)

% pie < (r^2*c)/(Q*lambda*Y-r*c)

tauTilde = 1/lambda*log((Q/(1-Q))*(((1-Q)*lambda*Y+r*c)/(Q*lambda*Y-r*c)));

%Y=10;
%c=.02;       
%r= .2;
%pie = .5;
%lambda = 1;
%delta = .4; %depreciation
%Q = .8;

dt = .05;
Tmax = 15;
tgrid = 0:dt:Tmax;
Nt = length(tgrid);

tauHvec = Tmax:2*dt:2*Tmax;
Ntau = length(tauHvec);

g = Q.*exp(-lambda.*tgrid)./(Q.*exp(-lambda.*tgrid)+1-Q);
pmax = lambda*Y/r-c;


for j=1:Ntau
    
    tauH = tauHvec(j)
    
    VHmaxt = (lambda*Y+pie*pmax)/(r+pie)*(1-exp(-(r+pie)*(tauH-tgrid)))+pmax*exp(-(r+pie)*(tauH-tgrid));
    
    VHmaxtTau(j,:) = VHmaxt;


qT = zeros(Nt);
ST = zeros(Nt);

for i=300
    
    q = nan(1,Nt);
    VH = nan(1,Nt);
   
    Ts=tgrid(i);
       
    for t=Nt+1-i:Nt
        
        if tgrid(Nt+1-t)>Ts
            q(Nt+1-t) = nan;
            VH(Nt+1-t) = nan;
        elseif tgrid(Nt+1-t)==Ts
            q(Nt+1-t) = 1;
            VH(Nt+1-t) = VHmaxt(Nt+1-t);
        else
            q(Nt+1-t) = q(Nt+2-t) - dt*((r)*(q(Nt+2-t)-r*c/(lambda*Y))+g(Nt+2-t)*(q(Nt+2-t)*lambda-r-((r)/(Y))*(VH(Nt+2-t)+c)));
            VH(Nt+1-t) = VH(Nt+2-t) - dt*((r+pie)*VH(Nt+2-t)-lambda*Y*(r+pie*q(Nt+2-t))/(r)+pie*c);
        end
        
        qT(i,:)=q;
        ST(i,:)=VH-(q*lambda*Y/r-c);
      
    end
    
end

    qTau(j,:)=q;
    STau(j,:)=VH-(q*lambda*Y/r-c);

end

STt=ST.';

figure; plot(tgrid,STau(1:10:Ntau,:))
figure; plot(tgrid,qTau(1:10:Ntau,:))
