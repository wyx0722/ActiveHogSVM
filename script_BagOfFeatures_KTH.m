clear;close all;
clc;


option = GetDefaultConfig('KTH');

%%% load third-part libs
addpath(genpath('SVM-chi-square-master'));
addpath(genpath('fcl-master/matlab/kmeans'));

eval_res = {};

    
%%% locate the extracted stip features
files_trainval =...
  sprintf('%s/stip_features/KTH_trainval.stip_harris3d.txt',option.fileIO.dataset_path);
files_test =...
  sprintf('%s/stip_features/KTH_test.stip_harris3d.txt',option.fileIO.dataset_path);
fprintf('- reading extracted stip features...\n');
stip_data_S = ReadSTIPFile(files_trainval,option);
stip_data_T = ReadSTIPFile(files_test,option);

fprintf('- generating codebook...\n');
%%% notice that the codebook is generated only from training data
[codebook,SUMD,opts,running_info,mu,sigma] = CreateCodebook(stip_data_S,option);
eval_res.CodebookLearning.codebook = codebook;
eval_res.CodebookLearning.SUMD = SUMD;
eval_res.CodebookLearning.opts = opts;
eval_res.CodebookLearning.running_info = running_info;
eval_res.RawFeatureStandardization.mu = mu;
eval_res.RawFeatureStandardization.sigma = sigma;
    

%%% encoding features, train and test linear svm
[eval_res.svm.model,eval_res.svm.Yt,eval_res.svm.Yp,eval_res.svm.meta_res]...
    = ActivityRecognition(codebook,stip_data_S,stip_data_T,mu,sigma,option);
eval_res.svm.accuracy = sum(eval_res.svm.Yt==eval_res.svm.Yp')/length(eval_res.svm.Yt);
cm = zeros(6,6);
for ii = 1:length(eval_res.svm.Yt)
    cm(eval_res.svm.Yt(ii),eval_res.svm.Yp(ii)) = ...
        cm(eval_res.svm.Yt(ii),eval_res.svm.Yp(ii))+1;
end
eval_res.svm.confusion_matrix = cm;
clear codebook stip_data_S stip_data_T 

save(option.fileIO.eval_res_file,'eval_res');
save(option.fileIO.option_file,'option');



