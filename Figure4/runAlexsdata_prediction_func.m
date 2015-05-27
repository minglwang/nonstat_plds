function output = runAlexsdata_prediction_func(data_file, output_folder, code_dir, k, Model)

cd(code_dir)

%Check if we got k as a string input instead of numeric, and convert
if ~isa(k, 'numeric')
    k = str2num(k);
end

[status, seed] = system('od /dev/urandom --read-bytes=4 -tu | awk ''{print $2}''');
seed=str2double(seed);
rng(seed);

addpath Figure4/
addpath Figure4/alex/
addpath Figure4/Analyze/
addpath standardEM/
addpath testcode_nonstationaryPLDS_varyingmeanfiringrate_prediction/
addpath gpml-matlab/gpml

%Check if we already did the initialization
if exist([output_folder filesep 'init_data.mat'], 'file')
  load([output_folder filesep 'init_data.mat'], 'newdataset', 'params', 'k');
  rtrain = length(params.ind_train);
  fprintf('Initialization has already been done.\n');
  
else
  
  load(data_file, 'resps', 'stims')

  %% splitting data into train and test parts

  ind_perm = randperm(size(resps,3));
  ind_test = sort(ind_perm((end-9):end));
  ind_train = sort(ind_perm(1:(end-10))); 
  rtrain = length(ind_train);

  params.ind_train = ind_train;
  params.ind_test = ind_test;

  %% Initialize parameters

  params.A = 0.9*eye(k); 
  params.C = randn(size(resps,1),k); %neuron num by latent dim
  params.B = randn(k,size(stims,1)); %latent dim by input dim
  params.inpn = stims; 
  fprintf('Fitting GP to initialize tau.\n');
  params.tau_init = GPfittingTrainingData(resps); %This returns initial estimate for tau

  params.x0 = zeros(k,1);
  params.V0 = eye(k);
  params.Q = eye(k);

  newdataset = cell(rtrain,1);
  yy =[];

  for i=1:rtrain
      newdataset{i}.y = resps(:,:,ind_train(i));
      newdataset{i}.T = size(resps,2); % time per trial
      newdataset{i}.inpn = stims;
      yy = [yy newdataset{i}.y];
  end

  meanyy = mean(yy,2);
  % meanyy(meanyy==0) = 0.1;
  params.d = log(meanyy);
  params.yy = yy; 
  
  tmp = reshape(params.yy,size(params.yy,1),length(params.ind_train),[]);
  tmp = mean(tmp,3);
  params.sig_init = 1.5*max(max(tmp,[],2) -min(tmp,[],2));
  params.m_h_init = zeros(k,1);

  save([output_folder filesep 'init_data.mat'], 'newdataset', 'params', 'k', 'Model');
end

%Additional sigma initialization
if ~isfield(params, 'sig_init')
  tmp = reshape(params.yy,size(params.yy,1),length(params.ind_train),[]);
  tmp = mean(tmp,3);
  params.sig_init = 1.5*max(max(tmp,[],2) -min(tmp,[],2)); %1.5 * maximum change in firing rate of a neuron over observed period
  save([output_folder filesep 'init_data.mat'], 'newdataset', 'params', 'k', 'Model');
end

if ~isfield(params, 'm_h_init')
  params.m_h_init = zeros(k,1);
  save([output_folder filesep 'init_data.mat'], 'newdataset', 'params', 'k', 'Model');
end

%%

datastruct = VBEM_PLDSnonstationary(newdataset, rtrain, params, Model, output_folder); 

save([output_folder filesep 'final_' Model '_data.mat'], 'datastruct', 'params');

fprintf('Params created and saved\n')


make_predictions(data_file, [output_folder filesep 'final_' Model '_data.mat'], [output_folder filesep 'init_data.mat'], code_dir, k, Model);
fprintf('Firing rate predictions done');

output = [];
return;

end