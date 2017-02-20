function codebook = CreateCodebook(dataset,subject,stip_data)
%%% This function creates the vocabulary for LEAVE-ONE-SUBJECT-OUT, the leaved subject is passed in the argument.
%%% This function returns a matrix, whose rows denote vocabularies and columns denote features.
%%% V1.0.1 In this version, the dataset and subject arguments are only for
%%% log files.
addpath(genpath('fcl-master/matlab/kmeans'));

NN = length(stip_data);
features = [];
for ii = 1:NN
    features = [features;stip_data{ii}.features(:,8:end)];
end

fprintf('-- #features=%i, feature_length=%i\n',size(features,1),size(features,2));

%%% Due to complexity, we randomly choose N features, if the #features > N.
N = 200000;
rng default;
if size(features,1)>N
   kk = randperm(size(features,1));
   features = features(kk(1:N),:);
end




%%% kmeans clustering with kmeans++ initialization and optimized algorithm.
fprintf('-- start kmeans clustering...\n');
NC = 4000;
%%% here we use the fcl lib for fast clustering. Initialization is kmeans++, and we dont run several times. 
opts.seed = 0;                  % change starting position of clustering
opts.algorithm = 'kmeans_optimized';     % change the algorithm to 'kmeans_optimized'
opts.init = 'kmeans++';           % use kmeans++ as initialization
opts.no_cores = -1;              % number of cores to use. for scientific experiments always use 1! -1 means using all
opts.max_iter = 100;             % stop after 10 iterations
opts.tol = 1e-5;                % change the tolerance to converge quicker
opts.silent = true;             % do not output anything while clustering
opts.remove_empty = true;       % remove empty clusters from resulting cluster center matrix
opts.additional_params.bv_annz = 0.125;
fprintf('-- clustering (optimized kmeans)....\n');
[ IDX, codebook,SUMD,running_info ] = fcl_kmeans(sparse(features'), NC, opts);
save(sprintf('Codebook_%s_subject%i.mat',dataset,subject),'running_info','opts','IDX','SUMD','codebook');
end
