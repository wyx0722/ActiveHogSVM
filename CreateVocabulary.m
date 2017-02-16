function vocabularies = CreateVocabulary(dataset,bodypart,subject)
%%% This function creates the vocabulary for LEAVE-ONE-SUBJECT-OUT, the leaved subject is passed in the argument.
%%% This function returns a matrix, whose rows denote vocabularies and columns denote features.

%%% set and parameter config
ant_path = ['annotation/',dataset];
info = importdata([ant_path,'/DataStructure.mat']);
video_path = info.dataset_path;
n_subs = info.num_subjects;
n_acts = info.num_activities;
n_trials = info.num_trials;
act_list = importdata([ant_path,'/activity_list.txt']);
addpath(genpath('fcl-master/matlab/kmeans'));
%%% load feature files
sub_list = 1:n_subs;
sub_list(sub_list==subject) = [];
features = [];
for ss = sub_list
  for aa = 1:n_acts
  for tt = 1:n_trials
  features = [features;importdata(sprintf('DenseMBH_Rochester/denseMBH_%sS%iR%i_%s.mat',act_list{aa}, ss,tt,bodypart))]; 
  end
  end
end

fprintf('-- #features=%i, feature_length=%i\n',size(features,1),size(features,2));

%%% Due to complexity, we randomly choose N features, if the #features > N.
N = 100000;
rng default;
if size(features,1)>N
   kk = randperm(size(features,1));
   features = features(kk(1:N),:);
end

%%% perform clustering
%%% Here use Kmeans clustering. Due to non-convexity, we perform K iterations and choose the best one.
NC = 4000; % #clusters
%rep = 5;
% clus = parcluster('local');
% clus.NumWorkers = 7;
% parpool(clus,7);
% stream = RandStream('mlfg6331_64');
% options = statset('UseParallel',1,'UseSubstreams',1,'Streams',stream);
% fprintf('-- clustering....\n');
% [idx,vocabularies] = kmeans(features,NC,'Options',options,'Replicates',rep);

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
[ ~, vocabularies ] = fcl_kmeans(features, NC, opts);


fprintf ('---finish...\n');
end
