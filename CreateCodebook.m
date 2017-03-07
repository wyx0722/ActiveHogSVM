function [codebook,SUMD,opts,running_info,mu,sigma] = CreateCodebook(stip_data,option)
%%% This function creates the vocabulary for LEAVE-ONE-SUBJECT-OUT, the leaved subject is passed in the argument.
%%% This function returns a matrix, whose rows denote vocabularies and columns denote features.
%%% V1.0.1 In this version, the dataset and subject arguments are only for
%%% log files.

NN = length(stip_data);
features = [];

if option.stip_features.including_scale
    dd = 8;
else
    dd = 10;
end


for ii = 1:NN
    features = [features;stip_data{ii}.features(:,dd:end)];
end

fprintf('-- #features=%i, feature_length=%i\n',size(features,1),size(features,2));

%%% Due to complexity, we randomly choose N features, if the #features > N.
N = option.codebook.maxsamples; % in previous settings, we set N = 200000 hdmb51, we wet 100000
rng default;
if size(features,1)>N
   kk = randperm(size(features,1));
   features = features(kk(1:N),:);
end

%%% data standardization
if option.stip_features.standardization
    mu = mean(features,1);
    sigma = std(features,1);
else
    mu = zeros(1,size(features,2));
    sigma = ones(1,size(features,2));
end
features = (features-repmat(mu,size(features,1),1))./repmat(sigma,size(features,1),1);



%%% kmeans clustering with kmeans++ initialization and optimized algorithm.
NC = option.codebook.NC;
%%% here we use the fcl lib for fast clustering. Initialization is kmeans++, and we dont run several times. 
opts.seed = 0;                  % change starting position of clustering
opts.algorithm = 'kmeans_optimized';     % change the algorithm to 'kmeans_optimized'
opts.init = 'kmeans++';           % use kmeans++ as initialization
opts.no_cores = 7;              % number of cores to use. for scientific experiments always use 1! -1 means using all
opts.max_iter = 100;             % stop after 100 iterations
opts.tol = 1e-5;                % change the tolerance to converge quicker
opts.silent = true;             % do not output anything while clustering
opts.remove_empty = true;       % remove empty clusters from resulting cluster center matrix
opts.additional_params.bv_annz = 0.125;
fprintf('-- clustering (optimized kmeans)....\n');
[ IDX, codebook,SUMD,running_info ] = fcl_kmeans(sparse(features'), NC, opts);

clear features stip_data
end
