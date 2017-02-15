 function [accuracy,prob_estimates,bestmodel,  class_label, meta_res]=Fu_direct_SVM2(Xtrain, Xtest, train_video_label,  test_video_label, opt)
%   [accuracy,prob_estimates,bestmodel,  class_label, meta_res]=Fu_direct_SVM2(Xtrain, Xtest, train_video_label,  test_video_label, opt) 
%
%  Aug.22,2013, Yanwei Fu
% This file is derived from Fu_direct_SVM.m
% --changing list: remove unnecessary and ambious conditions.
%                           This file directly compute SVM using low-level features by Chi2 kernel
%          
% Assumption: Xtrain, Xtest: each row is corrsponding to one instance.  
%
%   opt=getPrmDflt(opt, {'norm_type','row','permutation',0,'kernel','chi-square','nFold',3,'outProb', 1,'useWeight', true},-1);
% kernel: linear, RBF, chisq
%
% nFold, default number of cross-valiation fold.
% To reuse the model, cannot do any permutation.
if nargin<5
    opt = struct;
end

opt=getPrmDflt(opt, {'norm_type','row','permutation',0,'kernel','chi-square','nFold',3,'outProb', 1,'useWeight', true},-1);
global iif;
iif =@(varargin)varargin{2*find([varargin{1:2:end}],1,'first')}();
% data normalization functions:
ftrain =@(norm_type,Xtrain) iif(strcmp(norm_type,'row'), CCV_normalize(Xtrain,1), ...
                          strcmp(norm_type,'col'),  CCV_normalize(Xtrain,2), ...
                          1, Xtrain);  % else 'col'
ftest =@(norm_type,Xtest) iif(strcmp(norm_type,'row'), CCV_normalize(Xtest,1), ...
                            strcmp(norm_type,'col'), CCV_normalize(Xtest,2), ...
                            1, Xtest);

train_video_label = train_video_label(:);
test_video_label = test_video_label(:);
% do some errors checking:
if(size(Xtrain,2)~=size(Xtest,2))
        error('Xtrain and Xtest have mismatching dimension');
end
if(size(Xtest,1)~=size(test_video_label,1))
        error('Xtest and Ytest have mismatching numbers of elements');
end
if(size(Xtrain,1)==0 || size(train_video_label,1)==0)
    error('Xtrain or train_video_label has missing elements');
end

if(size(Xtest,1)==0 || size(test_video_label,1)==0)
    warning('Xtest or test_video_label has missing elements');
end

[N,nDim] = size(Xtrain);

if(numel(unique(train_video_label))~=max(train_video_label))
    disp('Warning: Max label ~= # unique labels!!');
end

%% Normalize data;
fprintf('normalizing.....\n');
Ytrain = ftrain(opt.norm_type, Xtrain);
Ytest = ftest(opt.norm_type, Xtest);
% do not do permutation in our experiments
% if opt.permutation
%     rndidx = randperm(size(Ytrain,1));
%     Ytrain = Ytrain(rndidx,:);
%     train_label = train_video_label(rndidx);
%     rndidx1 = randperm(size(Ytest,1));
%     Ytest = Ytest(rndidx1,:);
%     test_label = test_video_label(rndidx1);
% else
    train_label =train_video_label(:);
    test_label = test_video_label(:);
% end

%% calculate for chi2 kernel
if strcmp(opt.kernel,'chi-square')||strcmp(opt.kernel,'chisq')
    opt.customKernel = 1;
    % to invoke when cross validataion of a subset of data
    opt.makeKernelPtr =@Fu_compute_kernel_matrices; 
    [Ktrain, Ktest] = Fu_compute_kernel_matrices(Ytrain, Ytest);
    opt.K =[(1:numel(train_label))',Ktrain];
    Ktrain =opt.K;
    Ktest =[(1:numel(test_label))',Ktest];

    [c,g,bestcv,acc,cmat,bestmodel] = Fu_libsvm_cv(Ytrain,train_label,opt);
    
    [class_label, accuracy,prob_estimates] = svmpredict(test_label, ...
                                Ktest, bestmodel, '-b 1');
meta_res.Ktrain = Ktrain;
meta_res.Ktest = Ktest;
elseif strcmp(opt.kernel,'RBF')
   [c,g,bestcv,acc,cmat,bestmodel] = Fu_libsvm_cv(Ytrain,train_label,opt);
    [class_label, accuracy,prob_estimates] = svmpredict(test_label, ...
                                Ytest, bestmodel, '-b 1');
elseif strcmp(opt.kernel,'linear')
    opt.customKernel = 0;
     [c,g,bestcv,acc,cmat,bestmodel] = Fu_libsvm_cv(Ytrain,train_label,opt);
    [class_label, accuracy,prob_estimates] = svmpredict(test_label, ...
                                Ytest, bestmodel, '-b 1');
end
% results:
meta_res.c=c;
meta_res.g=g;
meta_res.bestcv = bestcv;
meta_res.cv_acc = acc;
meta_res.res_acc = accuracy;

