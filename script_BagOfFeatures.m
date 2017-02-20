clear;close all;
clc;

%%% this script implements the pipeline of bag of features for action
%%% recognition in RochesterADL
subjects = 1:5; % in the implementation, we perform leave-one-subject-out.
reg_res = {};
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
    [model,reg_res{ss}.acc,reg_res{ss}.cls,reg_res{ss}.meta_res]...
        = ActivityRecognition(codebook,stip_data_S,stip_data_T);
    
    clear codebook stip_data_S stip_data_T
end


    
    
    

