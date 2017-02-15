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
fprintf('Dataset: %s\n',dataset);

%%% load feature files
sub_list = 1:n_subs;
sub_list(sub_list==subject) = [];
features = [];
for ii = sub_list
  features = [features,importdata(sprintf('denseMBH_rochester_S%i_%s.mat',ii,bodypart)); 
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
rep = 8;
rng default; % for reproducing results
[idx,vocabularies] = kmeans(features,NC,'Replicates',rep);

end
