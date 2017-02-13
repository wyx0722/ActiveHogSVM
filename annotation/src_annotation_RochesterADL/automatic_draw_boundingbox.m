
%%%% special for the dataset rochester adl
clear;close all;
clc

action_list = importdata('annotation/Dataset_RochesterADL/activity_list.txt');
n_subjects = 5;
n_trials = 3;

%% generate bounding boxes for annotation
mm = load('rochester_head_model/esvm_head_1/models/head-svm-stripped.mat'); %% the model when s1 is excluded
mm2= load('rochester_head_model/esvm_head_5/models/head-svm-stripped.mat'); %% the model when s5 is excluded
for ss = 3:n_subjects
    if ss == 1
        models = mm2.models;
    else
        models = mm.models;
    end
    for tt = 1:n_trials
        for aa = 1:length(action_list)
            video = sprintf([action_list{aa},'S%iR%i.avi'],ss,tt);
            fprintf(['==processing ', video,'\n']);
            detection_body_part(video,models);
        end
    end
end


%% manually refine the bounding boxes
for ss = 4:5

    for tt = 1:n_trials
        for aa = 1:length(action_list)
            video = sprintf([action_list{aa},'S%iR%i.avi'],ss,tt);
            fprintf(['==processing ', video,'\n']);
            refine_body_part(video);
        end
    end
end