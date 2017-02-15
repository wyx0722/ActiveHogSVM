% some example SVM codes used in Yanwei Fu's work:
%[1] Fu et al. Learning Multi-modal Latent Attributes, TPAMI 2012
%[2] FU et al.  Attribute Learning for Understanding Unstructured Social Activity, ECCV 2012

%%
% add path
addpath('./internal/');
addpath_folder('./internal/');

%% load data:
% note that this mat file is not included in ./mat folder. Please download
% from http://www.eecs.qmul.ac.uk/~yf300/USAA/download/input.mat
load('./mat/input.mat');

addpath('./libsvm/matlab/');

%% MFCC baseline:
opt.nFold = 3; 
MFCCtr = Xtrain(:,10001:14000);
MFCCte = Xtest(:,10001:14000);
[acc_mfcc, prob_estimates_mfcc, bestmodel_mfcc, class_label_mfcc, meta_res_mfcc]=Fu_direct_SVM2(MFCCtr, MFCCte, train_video_label,test_video_label,opt);

%save('mfcc_test.mat','acc_mfcc', 'prob_estimates_mfcc', 'bestmodel_mfcc', 'class_label_mfcc', 'meta_res_mfcc');
%% MFCC+SIFT baseline:
% nFolder of cross-validatin:
opt.nFold = 3;  
MFCCSIFTtr = [CCV_normalize(Xtrain(:,[1:5000]),1),CCV_normalize(Xtrain(:,[10001:14000]),1)];
MFCCSIFTte = [CCV_normalize(Xtest(:,[1:5000]),1),CCV_normalize(Xtest(:,[10001:14000]),1)];
[acc_mfccsift, prob_estimates_mfccsift, bestmodel_mfccsift, class_label_mfccsift, meta_res_mfccsift]=Fu_direct_SVM2(MFCCSIFTtr, MFCCSIFTte, train_video_label,test_video_label,opt);
     
%% MFCC+SIFT+STIP
opt.nFold = 3; 
MFCCSIFTstiptr = [CCV_normalize(Xtrain(:,[1:5000]),1),CCV_normalize(Xtrain(:,[5001:10000]),1), CCV_normalize(Xtrain(:,[10001:14000]),1)];
MFCCSIFTstipte = [CCV_normalize(Xtest(:,[1:5000]),1),CCV_normalize(Xtest(:,[5001:10000]),1), CCV_normalize(Xtest(:,[10001:14000]),1)];
[acc_mfccsiftstip, prob_estimates_mfccsiftstip, bestmodel_mfccsiftstip, class_label_mfccsiftstip, meta_res_mfccsiftstip]=Fu_direct_SVM2(MFCCSIFTstiptr, MFCCSIFTstipte, train_video_label,test_video_label,opt);

%%  SIFT only:
opt.nFold = 3; 
SIFTtr = Xtrain(:,1:5000);
SIFTte = Xtest(:,1:5000);
[acc_sift, prob_estimates_sift, bestmodel_sift, class_label_sift, meta_res_sift]=Fu_direct_SVM2(SIFTtr, SIFTte, train_video_label,test_video_label,opt);

%%  STIP only:
opt.nFold = 3; 
STIPtr = Xtrain(:,5001:10000);
STIPte = Xtest(:,5001:10000);
[acc_stip, prob_estimates_stip, bestmodel_stip, class_label_stip, meta_res_stip]=Fu_direct_SVM2(STIPtr, STIPte, train_video_label,test_video_label,opt);

%% STIP+SIFT 
opt.nFold = 3; 
% MFCCSIFTtr = Xtrain(:,[1:5000,10000:14000]);
% MFCCSIFTte = Xtest(:,[1:5000, 10000:14000]);
SIFTSTIPtr = [CCV_normalize(Xtrain(:,[5001:10000]),1),CCV_normalize(Xtrain(:,[1:5000]),1)];
SIFTSTIPte = [CCV_normalize(Xtest(:,[5001:10000]),1),CCV_normalize(Xtest(:,[1:5000]),1)];
[acc_siftstip, prob_estimates_siftstip, bestmodel_siftstip, class_label_siftstip, meta_res_siftstip]=Fu_direct_SVM2(SIFTSTIPtr, SIFTSTIPte, train_video_label,test_video_label,opt);

%% STIP+MFCC
opt.nFold = 3; 
% MFCCSIFTtr = Xtrain(:,[1:5000,10000:14000]);
% MFCCSIFTte = Xtest(:,[1:5000, 10000:14000]);
MFCCSTIPtr = [CCV_normalize(Xtrain(:,[5001:10000]),1),CCV_normalize(Xtrain(:,[10001:14000]),1)];
MFCCSTIPte = [CCV_normalize(Xtest(:,[5001:10000]),1),CCV_normalize(Xtest(:,[10001:14000]),1)];
[acc_mfccstip, prob_estimates_mfccstip, bestmodel_mfccstip, class_label_mfccstip, meta_res_mfccstip]=Fu_direct_SVM2(MFCCSTIPtr, MFCCSTIPte, train_video_label,test_video_label,opt);
%%
save svm_baseline_all_combinations.mat
