function [model,Yt,cls,meta_res] = ActivityRecognition(codebook,...
    stip_data_train,stip_data_test,mu,sigma,option)

act_list = option.fileIO.act_list;

Xs = [];
Ys = [];
Xt = [];
Yt = [];
NN = length(stip_data_train);
NNt = length(stip_data_test);
disp('-- encoding features based on the codebook...');

if option.stip_features.including_scale
    dd = 8;
else
    dd = 10;
end


for ii = 1:NN  
    switch option.fileIO.dataset_name
        case 'RochesterADL'
            Ys(ii) = find(strcmp(act_list, stip_data_train{ii}.video(1:end-4)));
        case 'KTH'
            ss = strsplit(stip_data_train{ii}.video,'_');
            Ys(ii) = find(strcmp(act_list, ss{2}));
        case 'Weizmann'
            ss = strsplit(stip_data_train{ii}.video,'_');
            Ys(ii) = find(strcmp(act_list, ss{2}));
        case 'HMDB51'
            Ys(ii) = find(strcmp(act_list, stip_data_train{ii}.video));
        otherwise
            error('no othe option.');
            return;
    end
    
    if ~option.hyperfeatures.multilayerfeature
        Xs(ii,:) = Encoding(stip_data_train{ii}.features(:,dd:end),codebook,...
            mu,sigma,option);
    else
        last = Encoding(stip_data_train{ii}.features(:,dd:end),codebook,...
            mu,sigma,option);
        for ll = 1:option.hyperfeatures.num_layers-1
            last = [last stip_data_train{ii}.globalfeatures{ll}];
        end
        
        Xs(ii,:) = last ./ (sum(last)); % l1 -normalizing
    end
    stip_data_train{ii} = [];
end


for ii = 1:NNt
    
    switch option.fileIO.dataset_name
        case 'RochesterADL'
            Yt(ii) = find(strcmp(act_list, stip_data_test{ii}.video(1:end-4)));
        case 'KTH'
            ss = strsplit(stip_data_test{ii}.video,'_');
            Yt(ii) = find(strcmp(act_list, ss{2}));
        case 'Weizmann'
            ss = strsplit(stip_data_test{ii}.video,'_');
            Yt(ii) = find(strcmp(act_list, ss{2}));
        case 'HMDB51'
            Yt(ii) = find(strcmp(act_list, stip_data_test{ii}.video));
        otherwise
            error('no othe option.');
            return;
    end
      
    if ~option.hyperfeatures.multilayerfeature
        Xt(ii,:) = Encoding(stip_data_test{ii}.features(:,dd:end),codebook,...
            mu,sigma,option);
    else
        last = Encoding(stip_data_test{ii}.features(:,dd:end),codebook,...
            mu,sigma,option);
        for ll = 1:option.hyperfeatures.num_layers-1
            last = [last stip_data_test{ii}.globalfeatures{ll}];
        end
        
        Xt(ii,:) = last ./ (sum(last)); % l1 -normalizing
    end
    
    stip_data_test{ii} = [];
end


%%% processing data and train linear svm in a multi-class svm and optimize the hyper-parameters
%%% todo
fprintf('-- training and testing \n');
[model,acc,cls,meta_res] = TrainSVM(Xs,Ys,Xt,Yt,option);
end


function [bestmodel,acc,class_label,meta_res] = TrainSVM(Xs,Ys,Xt,Yt,option)
%%% X is a struct containing feature vectors in a context hierarchy.
%%% Y is the action label.

opt.nFold = option.svm.n_fold_cv; %%% rochester and weizmann, 5-fold cv; KTH 10-foldsave
opt.kernel = option.svm.kernel;
% Xtrain = CCV_normalize(Xs,1);
% Xtest = CCV_normalize(Xt,1);
[acc, prob_estimates, bestmodel, class_label, meta_res]...
        =Fu_direct_SVM2(Xs, Xt, Ys,Yt,opt);

end
