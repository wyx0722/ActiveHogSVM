clear;close all;
clc;






addpath(genpath('SVM-chi-square-master'));
%%% this script implements the pipeline of bag of features for action
%%% recognition in RochesterADL
trials = 1:3; % based on the 3 splits written in the paper or the website
reg_res = {};
model = {};







for tt = trials
   
    %%% list the folders, each folder name corresponds to an action label
    stip_data_S = {};
    stip_data_T = {};
    idxs = 1;
    idxt = 1;
    for kk = 1:length(act_list)
        workingDir = [data_path,'/',act_list{kk}];
        pack = importdata([split_path,'/',sprintf('%s_test_split%i.txt',act_list{kk},tt)]);
        split_label = pack.data;
        video_list = pack.textdata;
        for vv = 1:length(split_label)
            if split_label(vv)==1 % training
               stip_data_S{idxs}.video = act_list{kk};
               fprintf('- %s %i...\n',act_list{kk},split_label(vv));
               tmp = ReadSTIPFile([workingDir,'/',video_list{vv},'.txt'],'1.0');
               stip_data_S{idxs}.features = tmp{1}.features;
               idxs = idxs+1;
               clear tmp;
            elseif split_label(vv)==2 % testing
               stip_data_T{idxt}.video = act_list{kk};
               fprintf('- %s %i...\n',act_list{kk},split_label(vv));
               tmp = ReadSTIPFile([workingDir,'/',video_list{vv},'.txt'],'1.0');
               stip_data_T{idxt}.features = tmp{1}.features;
               idxt = idxt + 1;
               clear tmp;
            else
               continue;
            end
        end
    end

    %%% notice that the codebook is generated only from training data
    codebook = CreateCodebook('HMDB51',tt,stip_data_S);
    
    %%% encoding features, train and test linear svm
    [model{tt},reg_res{tt}.Yt,reg_res{tt}.Yp,reg_res{tt}.meta_res]...
        = ActivityRecognition(codebook,stip_data_S,stip_data_T);
    

%    figure;imagesc(cm);
    clear codebook stip_data_S stip_data_T
end

save('HMDB51_RegRes.mat','model','reg_res');    
    
    

