clear;close all;
clc;

addpath(genpath('SVM-chi-square-master'));
%%% this script implements the pipeline of bag of features for action
%%% recognition in KTH

reg_res = {};
cm = zeros(6,6);

    
%%% locate the extracted stip features
files_trainval =...
  sprintf('stip-2.0-linux/KTH_trainval.stip_harris3d.txt');
files_test =...
  sprintf('stip-2.0-linux/KTH_test.stip_harris3d.txt');
fprintf('- reading extracted stip features...\n');
stip_data_S = ReadSTIPFile(files_trainval);
stip_data_T = ReadSTIPFile(files_test);

fprintf('- generating codebook...\n');
%%% notice that the codebook is generated only from training data
codebook = CreateCodebook('KTH',1,stip_data_S);n

%%% encoding features, train and test linear svm
[model,reg_res.Yt,reg_res.Yp,reg_res.meta_res]...
    = ActivityRecognition(codebook,stip_data_S,stip_data_T);


for ii = 1:length(reg_res{ss}.Yt)
    cm(reg_res{ss}.Yt(ii),reg_res{ss}.Yp(ii)) = ...
        cm(reg_res{ss}.Yt(ii),reg_res{ss}.Yp(ii))+1;
end
%    figure;imagesc(cm);
clear codebook stip_data_S stip_data_T

reg_res.confusion_matrix = cm;





