clear;close all;
clc;


addpath(genpath('SVM-chi-square-master'));
addpath(genpath('fcl-master/matlab/kmeans'));
%%% this script implements the pipeline of bag of features for action
%%% recognition in HMDB51
option = GetDefaultConfig('HMDB51');
eval_res = {};



for tt = trials
   
    %%% list the folders, each folder name corresponds to an action label
    stip_data_S = {};
    stip_data_T = {};
    idxs = 1;
    idxt = 1;
    for kk = 1:length(act_list)
        workingDir = [option.fileIO.dataset_path,'/',option.act_list{kk}];
        splitpath = [option.fileIO.dataset_path '/testTrainMulti_7030_splits'];
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
%     codebook = CreateCodebook('HMDB51',tt,stip_data_S);
    [codebook,SUMD,opts,running_info,mu,sigma] = CreateCodebook(stip_data_S,option);
    eval_res{ss}.CodebookLearning.codebook = codebook;
    eval_res{ss}.CodebookLearning.SUMD = SUMD;
    eval_res{ss}.CodebookLearning.opts = opts;
    eval_res{ss}.CodebookLearning.running_info = running_info;
    eval_res{ss}.RawFeatureStandardization.mu = mu;
    eval_res{ss}.RawFeatureStandardization.sigma = sigma;
    %%% encoding features, train and test linear svm
    [eval_res{ss}.svm.model,eval_res{ss}.svm.Yt,eval_res{ss}.svm.Yp,eval_res{ss}.svm.meta_res]...
        = ActivityRecognition(codebook,stip_data_S,stip_data_T,mu,sigma,option);
    eval_res{ss}.svm.accuracy = sum(eval_res{ss}.svm.Yt==eval_res{ss}.svm.Yp')/length(eval_res{ss}.svm.Yt);
    cm = zeros(51,51);
    for ii = 1:length(eval_res{ss}.svm.Yt)
        cm(eval_res{ss}.svm.Yt(ii),eval_res{ss}.svm.Yp(ii)) = ...
            cm(eval_res{ss}.svm.Yt(ii),eval_res{ss}.svm.Yp(ii))+1;
    end
    eval_res{ss}.svm.confusion_matrix = cm;
    clear codebook stip_data_S stip_data_T 
end

save(option.fileIO.eval_res_file,'eval_res');
save(option.fileIO.option_file,'option');
    
    

