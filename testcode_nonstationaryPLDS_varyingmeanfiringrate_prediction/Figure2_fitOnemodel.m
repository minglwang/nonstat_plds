%% to fit the data for Figure 2

clear all;
close all;
clc;

% add path to use 'hinton' figure to show estimates
addpath ../mattBealsCode_v3_4_1/
addpath ../standardEM/
addpath ../testcode_nonstationaryPLDS_A_multipleRecordings/

%%
% load data
load all_NSFR.mat

r = 1;

% put all the true params
params.A = A;
params.B = B;
params.C = C;
params.d = d;
params.h = h;

params.x0 = x0;
params.V0 = V0;
params.Q = eye(k);

xyzinpn.inpn = repmat(inpn, [1 100]);
xyzinpn.y = yy;
xyzinpn.z = zz; 
params.inpn = xyzinpn.inpn;

%% start fitting here

% addpath ../testcode_nonstationaryPLDS_varyingmeanfiringrate/


Model = 'NSFR';
datastruct = VBEM_PLDSnonstationary(xyzinpn, r, params, Model); 

% save Figure2_OneModel.mat

%%

load Figure2_OneModel.mat

fromMstep = datastruct.Mstep{10};
fromEstep = datastruct.Estep{10};

xyzinpn.z = zz;

CC = fromMstep.C;
hh = fromMstep.h;
covhh = fromMstep.covh;
mu = fromEstep.mumarg;

numsubsets = 100; 

Cmud = zeros(p, numsubsets*T);
for t=1:numsubsets*T
    Cmud(:,t) = CC*(mu(:,t)+hh) + fromMstep.d;
end


z1_est = zeros(numsubsets, T);
z2_est = zeros(numsubsets, T);

z1 = zeros(numsubsets, T);
z2 = zeros(numsubsets, T);

corr_z_est = zeros(numsubsets,1);
corr_z = zeros(numsubsets, 1);

zestmat = zeros(p, T, numsubsets); 

invsigmat = fromEstep.inv_sigmarg;

for trial_to_check = 1: numsubsets

    zestmat(:,:,trial_to_check) = Cmud(:, (trial_to_check-1)*T + 1: trial_to_check*T);
    
    z1_est(trial_to_check,:) = sum(Cmud(1:p/2,(trial_to_check-1)*T + 1: trial_to_check*T));
    z2_est(trial_to_check,:) = sum(Cmud(p/2+1:p,(trial_to_check-1)*T + 1: trial_to_check*T));
    
    corr_z_est(trial_to_check) = corr(z1_est(trial_to_check,:)', z2_est(trial_to_check,:)');
    
    invsig = invsigmat(:,:,(trial_to_check-1)*T + 1: trial_to_check*T);
    covz_errbar = zeros(p, p, T);
    errorbar = zeros(p, T);
    for t=1:T
        covz_errbar(:,:,t) = CC*(inv(invsig(:,:,t))+covhh)*CC';
        errorbar(:,t) =  diag(covz_errbar(:,:,t));
    end
    
    
    % plot(1:T, k1k2mat(2,:,1)', 'k', 1:T, k1k2mat_est(2,:,1), 'r', 1:T, k1k2mat_est(2,:,1)-1.64*sqrt(sum(errorbar(1+p/2:p,:))), 'r--', 1:T, k1k2mat_est(2,:,1)+1.64*sqrt(sum(errorbar(1+p/2:p,:))), 'r--');
    % set(gca, 'ylim', [-45 -35])
    
    z1(trial_to_check,:) = sum(xyzinpn.z(1:p/2,(trial_to_check-1)*T + 1: trial_to_check*T));
    z2(trial_to_check,:) = sum(xyzinpn.z(p/2+1:p,(trial_to_check-1)*T + 1: trial_to_check*T));
    
    corr_z(trial_to_check) = corr(z1(trial_to_check,:)', z2(trial_to_check,:)'); 

end

figure
subplot(211);
plot(1:numsubsets, mean(z1,2)/(p/2),'r', 1:numsubsets, mean(z2,2)/(p/2), 'b', ...
    1:numsubsets, mean(z1_est,2)/(p/2), 'r--', 1:numsubsets, mean(z2_est,2)/(p/2), 'b--')

%%

numtimebins = T;
autocorr = zeros(p, numtimebins+1);

for whichcell = 1:p
%    autocorr(whichcell, :) = xcov(yy(whichcell,:), numtimebins/2, 'unbiased');
     autocorr(whichcell, :) = xcov(zz(whichcell,:), numtimebins/2, 'unbiased');
end

avgautocorr_acrcells = mean(autocorr);

% figure; plot(autocorr'); title('total auto-cov of each cell');

autocorr_condi = zeros(p, numtimebins+1, numsubsets);

for whichcell = 1:p
    
    for whichtrial = 1:numsubsets
        autocorr_condi(whichcell, :, whichtrial) = xcov(z(whichcell,:,whichtrial), numtimebins/2, 'unbiased');
%        autocorr_condi(whichcell, :, whichtrial) = xcov(y(whichcell,:,whichtrial), numtimebins/2, 'unbiased');
    end
    
end

autocorr_per_eachtrial = squeeze(mean(autocorr_condi));
avgautocorr_condi = mean(autocorr_per_eachtrial,2);

figure
plot(1:numtimebins+1, avgautocorr_acrcells/max(avgautocorr_acrcells), 'k', 1:numtimebins+1, avgautocorr_condi/max(avgautocorr_condi), 'r')
legend('total covariance', 'conditional covariance');

%%

zzz = [];
for i=1:r
    zzz = [zz zestmat(:,:,i)];
end

% numtimebins = T/4;
autocorr = zeros(p, numtimebins+1);

for whichcell = 1:p
%    autocorr(whichcell, :) = xcov(yy(whichcell,:), numtimebins/2, 'unbiased');
     autocorr(whichcell, :) = xcov(zzz(whichcell,:), numtimebins/2, 'unbiased');
end

avgautocorr_acrcells = mean(autocorr);

% figure; plot(autocorr'); title('total auto-cov of each cell');

autocorr_condi = zeros(p, numtimebins+1, numsubsets);

for whichcell = 1:p
    
    for whichtrial = 1:numsubsets
        autocorr_condi(whichcell, :, whichtrial) = xcov(zestmat(whichcell,:,whichtrial), numtimebins/2, 'unbiased');
%        autocorr_condi(whichcell, :, whichtrial) = xcov(y(whichcell,:,whichtrial), numtimebins/2, 'unbiased');
    end
    
end

autocorr_per_eachtrial = squeeze(mean(autocorr_condi));
avgautocorr_condi = mean(autocorr_per_eachtrial,2);

hold on; 
plot(1:numtimebins+1, avgautocorr_acrcells/max(avgautocorr_acrcells), 'k--', 1:numtimebins+1, avgautocorr_condi/max(avgautocorr_condi), 'r--')

%%