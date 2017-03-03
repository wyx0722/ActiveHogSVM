clear;close all;
clc;


option = GetDefaultConfig('RochesterADL');

%%% load third-part libs
addpath(genpath('SVM-chi-square-master'));
addpath(genpath('fcl-master/matlab/kmeans'));

%%% this script implements the pipeline of bag of features for action
%%% recognition in RochesterADL
subjects = 1:5; % in the implementation, we perform leave-one-subject-out.
eval_res = {};

%%% main loop
for ss = subjects
    
    %%% locate the extracted stip features
    files_training =...
      sprintf('%s/stip_features/RochesterADL_leave_subject%i_out.stip_harris3d.txt',option.fileIO.dataset_path,ss);
    files_testing =...
      sprintf('%s/stip_features/RochesterADL_subject%i.stip_harris3d.txt',option.fileIO.dataset_path,ss);
    fprintf('- reading extracted stip features...\n');
    stip_data_S = ReadSTIPFile(files_training,option);
    stip_data_T = ReadSTIPFile(files_testing,option);
    
    fprintf('- generating codebook...\n');
    %%% notice that the codebook is generated only from training data
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
    cm = zeros(10,10);
    for ii = 1:length(eval_res{ss}.svm.Yt)
        cm(eval_res{ss}.svm.Yt(ii),eval_res{ss}.svm.Yp(ii)) = ...
            cm(eval_res{ss}.svm.Yt(ii),eval_res{ss}.svm.Yp(ii))+1;
    end
    eval_res{ss}.svm.confusion_matrix = cm;
    clear codebook stip_data_S stip_data_T 
end

save(option.fileIO.eval_res_file,'eval_res');q
save(option.fileIO.option_file,'option');
    
    
    

