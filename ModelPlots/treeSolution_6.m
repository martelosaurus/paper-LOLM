clear all 

% isIncreasing = @(x) all(diff(x) > 0); 
interpFun = @(x,y,xi) interp1(x,y,xi,'linear','extrap'); 
% issortedUpDown = @(x) issorted(x) || issorted(flipud(x)); 
% interpFun = @(x,y,xi) interp1q(x,y,xi); 
% isGoodValueFunction = @(x) all(x(:) >= 0) && issortedUpDown(x(:)); 

Nstep = 20000; % size of time vector
M = 5000; % size of belief vector

H = 1; % high type drift $%%%%%%%%%%%% CAN THIS BE RAISED??? %%%%%%%%%%%%%%%%%
L = 0; % low type drift
sigma = 1; % volatility

phi = (H-L)/sigma; % signal to noise ration

pie = 0.4; % intensity of liquiidity sale %%%%%%%%%% CAN THIS BE LOWERED??? %%%%%%%%%%%%%%

r = 0.5; % discount rate r*dt

c = .1; % transaction cost at time of sale

T = 20; % length of time

dx = 1/(1+M);
dt = T/(1+Nstep);

xgrid = linspace(0  , 1  , M+1    )'; 
tgrid = linspace(0  , T  , Nstep+1)';

% assert(isIncreasing(xgrid)); % needs to be increasing for interp1q 

x0 = .8; % initial belief

p = (x0*H + (1-x0)*L - c)*ones(1,Nstep+1); % starting price for first loop % flow value multiplied by r below so price need not be divided by r

lBound_guess = (x0)'.*ones(1,Nstep+1);

for loop = 1:50

Vmat = nan(M+1, Nstep+1); % value fucntion for each belief at each point in time

lBound = nan(1, Nstep+1); % belief boundary
vBound = nan(1, Nstep+1); % value function at boundary belief

Vmat(:,end) = max((xgrid*r*H+(1-xgrid)*r*L+pie*p(end))/(r+pie), p(end)); % not sure what to do here - current assumption is game ends, so choose either last price or keep asset forever

for stepIdx = 1:Nstep; % stepIdx = 1; % stepIdx = 2; % stepIdx = 3; % stepIdx = floor(Nstep/4); 
    
    if(0 == mod(stepIdx,1000) ); 
        fprintf('%d of %d iterations completed\n', stepIdx, Nstep); 
    end;
    
    upval = xgrid  + phi * 1 * xgrid .* (1-xgrid) .* sqrt(dt); % up part of belief proccess
    dnval = xgrid  - phi * 1 * xgrid .* (1-xgrid) .* sqrt(dt); % down part of belief process
    
    VupContval = interpFun(xgrid, Vmat(:,end-stepIdx+1), upval); % interpolate value if falls between discrete beliefs 
    VdnContval = interpFun(xgrid, Vmat(:,end-stepIdx+1), dnval);
    
    V_cont = (VupContval + VdnContval) / 2; % 
   
    vval = max( [ (p(end-stepIdx))*ones(M+1,1), dt*(xgrid*r*H+(1-xgrid)*r*L)+ pie*dt*(p(end-stepIdx+1))*ones(M+1,1) + (1-pie*dt)*(1-r*dt)*V_cont], [], 2); % seller optimally chooses whether to sell or continue
    
    contV = (vval < (p(end-stepIdx))*ones(M+1,1)+.00001); % indices of the x values at which you continue (don't sell) - adjust by .001 to smooth over indifference
    
    % [vval, V_cont]
    
    % fIX THESE
    if contV(1)==0
        lBound(end-stepIdx) = xgrid(1); % belief boundary
        vBound(end-stepIdx) = vval(1); % value function at boundary belief
    
    elseif contV(M+1)==1
       
        lBound(end-stepIdx) = xgrid(M+1); % belief boundary
        vBound(end-stepIdx) = vval(M+1); % value function at boundary belief
    else
        lBound(end-stepIdx) = xgrid(find(contV>0, 1, 'last' )); % belief boundary
        vBound(end-stepIdx) = vval(find(contV>0, 1, 'last' )); % value function at boundary belief
    end
    
    Vmat(:,end-stepIdx) = vval; 
 
end

lBound(end)=lBound(end-1);
lBound_guess = (.2*lBound+.8*lBound_guess);
%close all 
%figure; mesh( tgrid, xgrid, Vmat ); title('V'); xlabel('t'); ylabel('x'); 
%figure; plot( tgrid, lBound(:));
%figure; plot( xgrid, Vmat(:,1));

[bb,Gam_H,gam_H,lam_H,Gam_L,gam_L,lam_L]  = thresh2belief( tgrid, lBound_guess, 20000, x0, pie, H, L, sigma ); 

%bb = x0*(gam_H+(1-Gam_H)*pie)./(x0*(gam_H+(1-Gam_H)*pie)+(1-x0)*(gam_L+(1-Gam_L)*pie)); %construct buyers' beliefs

p = bb*H + (1-bb)*L - c; %construct price from buyers' beliefs

p(end)=H-c;

loop

end


pdf = exp(-pie*tgrid).*(x0*(gam_H+(1-Gam_H)*pie)+(1-x0)*(gam_L+(1-Gam_L)*pie))'; %ex ante probability of sale at t
cdf = 1-exp(-pie*tgrid) + exp(-pie*tgrid).*(x0*Gam_H+(1-x0)*Gam_L)';
cdf2 = cumsum(pdf*dt); %to confirm that pdf and cdf seem correct - should be case that cdf=cdf2
haz = pdf./(1-cdf);


figure; plot( tgrid, [vBound(:), p(:)])
figure; plot( xgrid, Vmat(:,1000), xgrid, p(1000)*ones(1,M+1))
%boundary = Vmat(:,1)
%save('boundary.mat','boundary')
%figure; plot( tgrid, haz)

pdfLiq = exp(-pie*tgrid).*(x0*gam_H+(1-x0)*gam_L)';
pdfStrat = exp(-pie*tgrid).*(x0*(1-Gam_H)+(1-x0)*(1-Gam_L))'*pie;

figure; plot(tgrid,gam_H,tgrid,gam_L,tgrid,x0*gam_H+(1-x0)*gam_L)

% plot(tgrid, cumsum(gam_H*dt), tgrid, Gam_H)

% r = 30:40; 
% c = 01:10; 
% tgrid(r) 
% xgrid(c) 
% Vmat(r,c) 


% if( false ) 
%     Nstep = 10000; 
%     T = 2; 
% 
%     dt = T / Nstep; 
%     t  = (1:Nstep)' * dt; 
% 
%     population = [-1;+1]; 
% 
%     increments = sqrt(dt) * randsample(population,Nstep,true); 
% 
%     % plot( cumsum(increments) )
%     x0 = 1; 
%     Xt = nan(Nstep,1); 
%     Xt(1) = x0; 
% 
%     for stepIdx = 2:Nstep % stepIdx = 2; 
%         Xt(stepIdx) = (1 - dt / (T - t(stepIdx))) * Xt(stepIdx-1) + increments(stepIdx-1); 
%     end
% 
%     plot(t,Xt)
% end
