clear all

%Y=100;
Y=1;
k=.2;       %transaction cost (-k)
r=.01;
pie = .3;
lambda = 1;

Q = .99;
wH = 1;
wL = 0;
%Q = .5;
%wH = .8;
%wL = .2;
a=Q*wH+(1-Q)*wL;

dt = .0025;
T = 10;

t = dt:dt:T;
n = length(t);

b1= .5;
b2= 1.5;
b3= 3.5;
b4= 6.5;

epsilon = .1;

YY= Q*lambda*Y/r;

A0= 2/6;
A1= 1/6;
A2= 3/6;
A3= 1/6;
A4= 1;

P = zeros(1,n);
P(t<=b1-epsilon) = A0*YY;
P(and(t>b1-epsilon,t<=b1+epsilon)) = YY*((A1-A0)/(2*epsilon)*t(and(t>b1-epsilon,t<=b1+epsilon))+A0-(A1-A0)/(2*epsilon)*(b1-epsilon));
P(and(t>b1+epsilon,t<=b2-epsilon)) = A1*YY;
P(and(t>b2-epsilon,t<=b2+epsilon)) = YY*((A2-A1)/(2*epsilon)*t(and(t>b2-epsilon,t<=b2+epsilon))+A1-(A2-A1)/(2*epsilon)*(b2-epsilon));
P(and(t>b2+epsilon,t<=b3-epsilon)) = A2*YY;
P(and(t>b3-epsilon,t<=b3+epsilon)) = YY*((A3-A2)/(2*epsilon)*t(and(t>b3-epsilon,t<=b3+epsilon))+A2-(A3-A2)/(2*epsilon)*(b3-epsilon));
P(and(t>b3+epsilon,t<=b4-epsilon)) = A3*YY;
P(and(t>b4-epsilon,t<=b4+epsilon)) = YY*((A4-A3)/(2*epsilon)*t(and(t>b4-epsilon,t<=b4+epsilon))+A3-(A4-A3)/(2*epsilon)*(b4-epsilon));
P(t>b4+epsilon) = A4*YY;
P(P < 0) = 0;
P(P > lambda*Y/r) = lambda*Y/r;
%plot(t,P)

Vo1=zeros(1,n);
Vo1(n)=(pie*P(n)+lambda*Y)/(r+pie);
for i=1:n-1;
    Vo1(n-i)=pie*dt*P(n-i)+lambda*dt*Y+(1-pie*dt)*Vo1(n+1-i)/(1+r*dt);
end

g=(((1-lambda.*dt).^(t/dt))*(a))./(((1-lambda.*dt).^(t/dt))*(a)+(1-a));
gamma = 0.*ones(1,n);
gamma(end)=0;

for j=1:n

    Vo(j,:) = zeros(1,n);
    Vo(j,j:n)=P(j:n);

    for i=1:j-1
        Vo(j,j-i)=pie*dt*P(j-i)+g(j-i)*lambda*dt*(Y+Vo1(j+1-i)/(1+r*dt))+(1-pie*dt-g(j-i)*lambda*dt)*gamma(j-i)*dt*P(j-i)+(1-pie*dt-g(j-i)*lambda*dt-(1-pie*dt-g(j-i)*lambda*dt)*gamma(j-i)*dt)*Vo(j,j-i+1)/(1+r*dt);
    end

end

[val ind] = min(-Vo(:,1));

figure; plot(t,Vo(ind,:),t,P)

[val2 ind2] = min(Vo(ind,:));

P(ind2)

S = Vo1-Vo(ind,:);

SurpBound = 2*(1-g).*lambda*Y./(r+pie+lambda*(2*g-1));
SurpBound(SurpBound > lambda*Y/r) = lambda*Y/r;
SurpBound(SurpBound < 0) = nan;

figure; plot(t,S,t,(1-g).*lambda*Y/(r+pie),t,SurpBound)
axis([0 T 0 .2])

gPrime = [0, diff(g)/dt];
Sprime = [0, diff(S)/dt];
Pprime = [0, diff(P)/dt];
VoPrime = [0, diff(Vo(ind,:))/dt];
VoPrimePrime = [0, diff(VoPrime)/dt];

figure; plot(t,VoPrime)
axis([0 T -.5 .5])

boundCon = 2*(1-g)*lambda*Y+(lambda-r-pie-2*g*lambda).*S;

plot(t,boundCon)
axis([0 T -.05 .05])

