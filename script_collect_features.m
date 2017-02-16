clear;close all;clc


%%% dataset and parameter config
dataset = 'Dataset_RochesterADL';
ant_path = ['annotation/',dataset];
info = importdata([ant_path,'/DataStructure.mat']);
video_path = info.dataset_path;
n_subs = info.num_subjects;
n_acts = info.num_activities;
n_trials = info.num_trials;
act_list = importdata([ant_path,'/activity_list.txt']);
fprintf('Dataset: %s\n',dataset);

features_head = {};
features_person = {};
features_torso = {};

for aa = 1:n_acts
for ss = 1:n_subs
for tt = 1:n_trials

%     features_head = collect_features('Dataset_RochesterADL', 'head', ss,act_list{aa},tt);
%     save(sprintf('denseMBH_%sS%iR%i_head.mat',act_list{aa},ss,tt),'features_head');
%     clear features_head
     
%     features_torso = collect_features('Dataset_RochesterADL', 'torso', ss,act_list{aa},tt);
%     save(sprintf('denseMBH_%sS%iR%i_torso.mat',act_list{aa},ss,tt),'features_torso');
%     clear features_torso
    features_person = collect_features('Dataset_RochesterADL', 'person', ss,act_list{aa},tt);
    save(sprintf('DenseMBH_Rochester/denseMBH_%sS%iR%i_person.mat',act_list{aa},ss,tt),'features_person');
    clear features_person
    
end
end
end
