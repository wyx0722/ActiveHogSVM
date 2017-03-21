clear;close all;
clc;

addpath(genpath('SVM-chi-square-master'));
addpath(genpath('fcl-master/matlab/kmeans'));
addpath(genpath('tSNE'));
%% read train and test data
files_trainval =...
  sprintf('%s/stip_features/KTH_trainval.stip_harris3d.txt',option.fileIO.dataset_path);
files_test =...
  sprintf('%s/stip_features/KTH_test.stip_harris3d.txt',option.fileIO.dataset_path);
stip_data_S = ReadSTIPFile(files_trainval,option);
stip_data_T = ReadSTIPFile(files_test,option);

eval_res = {};
%% specify configuration
option = V2_GetDefaultConfig('KTH');

%% extract poselet occurance features.
stip_data_S = V2_PoseletFeatureExtraction(stip_data_S,option);
stip_data_T = V2_PoseletFeatureExtraction(stip_data_T,option);

%% codebook generation. At current stage, we learn the codebook separately for poselet and stips

%%% notice that the codebook is generated only from training data
[codebook_stip,SUMD_stip,opts_stip,running_info_stip,mu_stip,sigma_stip]...
    = V2_CreateCodebook(stip_data_S,option,'stip');
eval_res.CodebookLearning.codebook_stip = codebook_stip;
eval_res.CodebookLearning.SUMD_stip = SUMD_stip;
eval_res.CodebookLearning.opts_stip = opts_stip;
eval_res.CodebookLearning.running_info_stip = running_info_stip;
eval_res.RawFeatureStandardization.mu_stip = mu_stip;
eval_res.RawFeatureStandardization.sigma_stip = sigma_stip;

[codebook_poselet,SUMD_poselet,opts_poselet,running_info_poselet,mu_poselet,sigma_poselet]...
    = V2_CreateCodebook(stip_data_S,option,'stip');
eval_res.CodebookLearning.codebook_poselet = codebook_poselet;
eval_res.CodebookLearning.SUMD_poselet = SUMD_poselet;
eval_res.CodebookLearning.opts_poselet = opts_poselet;
eval_res.CodebookLearning.running_info_poselet = running_info_poselet;
eval_res.RawFeatureStandardization.mu_poselet = mu_poselet;
eval_res.RawFeatureStandardization.sigma_poselet = sigma_poselet;

%% encoding and pooling video snippets.Each feature vector is l1-normalized.
stip_S_encoded = V2_LocalFeatureEncoding(stip_data_S,codebook_poselet,...
    codebook_stip,mu_poselet,mu_stip,sigma_poselet,sigma_stip,option);

stip_T_encoded = V2_LocalFeatureEncoding(stip_data_T,codebook_poselet,...
    codebook_stip,mu_poselet,mu_stip,sigma_poselet,sigma_stip,option);

%% multi-class svm train








