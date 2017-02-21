function [model,Yt,cls,meta_res] = ActivityRecognition(codebook,stip_data_train,stip_data_test)


%%% specify feature data and labels
act_list = importdata('annotation/Dataset_RochesterADL/activity_list.txt');

Xs = [];
Ys = [];
Xt = [];
Yt = [];
NN = length(stip_data_train);
NNt = length(stip_data_test);
disp('-- encoding features based on the codebook...');
for ii = 1:NN
    
    Ys(ii) = find(strcmp(act_list, stip_data_train{ii}.video(1:end-4)));
    Xs(ii,:) = Encoding(stip_data_train{ii}.features(:,8:end),codebook);
    stip_data_train{ii} = [];
    

end

for ii = 1:NNt
    
    Yt(ii) = find(strcmp(act_list, stip_data_test{ii}.video(1:end-4)));
    Xt(ii,:) = Encoding(stip_data_test{ii}.features(:,8:end),codebook);
    stip_data_test{ii} = [];

end





%%% processing data and train linear svm in a multi-class svm and optimize the hyper-parameters
%%% todo
fprintf('-- training and testing \n');
[model,acc,cls,meta_res] = TrainSVM(Xs,Ys,Xt,Yt);

end


function [bestmodel,acc,class_label,meta_res] = TrainSVM(Xs,Ys,Xt,Yt)
%%% X is a struct containing feature vectors in a context hierarchy.
%%% Y is the action label.

opt.nFold = 5;
opt.kernel = 'linear';
Xtrain = CCV_normalize(Xs,1);
Xtest = CCV_normalize(Xt,1);
[acc, prob_estimates, bestmodel, class_label, meta_res]...
        =Fu_direct_SVM2(Xtrain, Xtest, Ys,Yt,opt);

end
