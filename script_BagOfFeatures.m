clear;close all;
clc;

addpath(genpath('SVM-chi-square-master'));
%%% this script implements the pipeline of bag of features for action
%%% recognition in RochesterADL
subjects = 5; % in the implementation, we perform leave-one-subject-out.
% reg_res = {};
% cm = zeros(10,10);
for ss = subjects
    
    %%% locate the extracted stip features
    files_training =...
      sprintf('stip-2.0-linux/RochesterADL_leave_subject%i_out.stip_harris3d.txt',ss);
    files_testing =...
      sprintf('stip-2.0-linux/RochesterADL_subject%i.stip_harris3d.txt',ss);
    fprintf('- reading extracted stip features...\n');
    stip_data_S = ReadSTIPFile(files_training);
    stip_data_T = ReadSTIPFile(files_testing);
    
    fprintf('- generating codebook...\n');
    %%% notice that the codebook is generated only from training data
    codebook = CreateCodebook('RochesterADL',ss,stip_data_S);
    
    %%% encoding features, train and test linear svm
    [model,reg_res{ss}.Yt,reg_res{ss}.Yp,reg_res{ss}.meta_res]...
        = ActivityRecognition(codebook,stip_data_S,stip_data_T);
    

    for ii = 1:length(reg_res{ss}.Yt)
        cm(reg_res{ss}.Yt(ii),reg_res{ss}.Yp(ii)) = ...
            cm(reg_res{ss}.Yt(ii),reg_res{ss}.Yp(ii))+1;
    end
    figure;imagesc(cm);
    clear codebook stip_data_S stip_data_T
end
reg_res.confusion_matrix = cm;


    
    
    

