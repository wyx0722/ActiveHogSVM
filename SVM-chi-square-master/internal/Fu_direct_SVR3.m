 function [accuracy,prob_estimates,bestmodel,  class_label, meta_res]=Fu_direct_SVR3(Xtrain, Xtest, train_video_label,  test_video_label, opt)
%   [accuracy,prob_estimates,bestmodel,  class_label, meta_res]=Fu_direct_SVR3(Xtrain, Xtest, train_video_label,  test_video_label, opt)
%
%  Aug.22,2013, Yanwei Fu
% This file is derived from Fu_direct_SVM.m
% --changing list: remove unnecessary and ambious conditions.
%                           This file directly compute SVM using low-level features by Chi2 kernel
%          
% Assumption: Xtrain, Xtest: each row is corrsponding to one instance.  
%
% Aug.24, 2013, Yanwei Fu
%  This file is changed from Fu_direct_SVM2.m,
%------ wrapping the SVR process.
%

% nFold, default number of cross-valiation fold.
% To reuse the model, cannot do any permutation.

% important parameters:
opt=getPrmDflt(opt, {'norm_type','row','kernel','chi-square','outProb', 1,'useWeight', true, 'do_CV',1},-1);

% inner parameters:  SVR,
opt=getPrmDflt(opt, {'permutation',0,'nFold',3, 'svmtype', 3},-1);

global iif;
iif =@(varargin)varargin{2*find([varargin{1:2:end}],1,'first')}();
% data normalization functions:
ftrain =@(x) iif(strcmp(opt.norm_type,'row'), CCV_normalize(Xtrain,1), ...
                          strcmp(opt.norm_type,'col'),  CCV_normalize(Xtrain,2), ...  % 'col'
                          1, Xtrain); % else no normalize
ftest =@(x) iif(strcmp(opt.norm_type,'row'), CCV_normalize(Xtest,1), ...
                            strcmp(opt.norm_type,'col'), CCV_normalize(Xtest,2), ...
                            1, Xtest);
                        

%% Normalize data;
fprintf('normalizing.....\n');
Ytrain = ftrain(opt);
Ytest = ftest(opt);
% do not do permutation in our experiments
% if opt.permutation
%     rndidx = randperm(size(Ytrain,1));
%     Ytrain = Ytrain(rndidx,:);
%     train_label = train_video_label(rndidx);
%     rndidx1 = randperm(size(Ytest,1));
%     Ytest = Ytest(rndidx1,:);
%     test_label = test_video_label(rndidx1);
% else
    train_label =train_video_label;
    test_label = test_video_label;
% end

%% calculate for chi2 kernel
if strcmp(opt.kernel,'chi-square')
    opt.customKernel = 1;
    % to invoke when cross validataion of a subset of data
    opt.makeKernelPtr =@Fu_compute_kernel_matrices; 
    [Ktrain, Ktest] = Fu_compute_kernel_matrices(Ytrain, Ytest);
    opt.K =[(1:numel(train_label))',Ktrain];
    Ktrain =opt.K;
    Ktest =[(1:numel(test_label))',Ktest];
    
    if opt.do_CV==1
        [c,g,bestcv,acc,cmat,bestmodel] = Fu_libsvr_cv(Ktrain,train_label(:),opt);
    else
        c = opt.C; 
        bestmodel = libsvmtrain(); % to be added.
    end
    
    [class_label, accuracy,prob_estimates] = svmpredict(test_label, ...
                                Ktest, bestmodel);
meta_res.Ktrain = Ktrain;
meta_res.Ktest = Ktest;
elseif strcmp(opt.kernel,'RBF')
    if opt.do_CV ==1
       [c,g,bestcv,acc,cmat,bestmodel] = Fu_libsvr_cv(Ytrain,train_label,opt);
    else
        c =opt.C; 
        bestmodel = libsvmtrain();
    end
   [class_label, accuracy,prob_estimates] = svmpredict(test_label, ...
                                Ytest, bestmodel);
elseif strcmp(opt.kernel,'linear')
    if opt.do_CV==1
        [c,g,bestcv,acc,cmat,bestmodel] = Fu_libsvr_cv(Ytrain,train_label,opt);
    else
        c =opt.C; 
        bestmodel = libsvmtrain();
    end
    
    [class_label, accuracy,prob_estimates] = svmpredict(test_label, ...
                                Ytest, bestmodel);   
end
% results:
meta_res.c=c;
meta_res.g=g;
meta_res.bestcv = bestcv;
meta_res.cv_acc = acc;
meta_res.res_acc = accuracy;

