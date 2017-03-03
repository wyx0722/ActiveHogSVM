function [model,Yt,cls,meta_res] = ActivityRecognition(codebook,stip_data_train,stip_data_test)


%%% specify feature data and labels
%%% if RochesterADL
% act_list = importdata('annotation/Dataset_RochesterADL/activity_list.txt');

%%% if Weizmann
% act_list = {'bend','jack','jump','pjump','run','side','skip','walk','wave1','wave2'};

%%% if KTH
act_list = {'boxing','handclapping','handwaving','jogging','running','walking'};

%%% if HMDB51
% act_list = {'brush_hair','cartwheel','catch','chew','clap','climb','dive','draw_sword','dribble'...
% ,'drink','eat','fall_floor','fencing','flic_flac','golf','handstand','hit','hug','jump',...
% 'kick_ball','kick','kiss','laugh','pick','pour','pullup','punch','push','pushup','ride_bike',...
% 'ride_horse','run','shake_hands','shoot_ball','shoot_bow','shoot_gun','sit','situp','smile',...
% 'smoke','somerault','stand','swing_baseball','sword_exercise','sword','talk','throw','turn',...
% 'walk','wave'};




Xs = [];
Ys = [];
Xt = [];
Yt = [];
NN = length(stip_data_train);
NNt = length(stip_data_test);
disp('-- encoding features based on the codebook...');
for ii = 1:NN
    
    %%% if RochesterADL
%     Ys(ii) = find(strcmp(act_list, stip_data_train{ii}.video(1:end-4)));
    %%% if Weizmann or KTH
    ss = strsplit(stip_data_train{ii}.video,'_');
    Ys(ii) = find(strcmp(act_list, ss{2}));
    %%% if HMDB51 
%     Ys(ii) = find(strcmp(act_list, stip_data_train{ii}.video));

    %%% spatio and temporal scales are included as feature.
%     Xs(ii,:) = Encoding(stip_data_train{ii}.features(:,8:end),codebook);
    %%% only HOG and HOF are features.
    Xs(ii,:) = Encoding(stip_data_train{ii}.features(:,10:end),codebook);
    
    stip_data_train{ii} = [];
    

end

for ii = 1:NNt
    
    %%% if RochesterADL
%     Yt(ii) = find(strcmp(act_list, stip_data_test{ii}.video(1:end-4)));

    %%% if weizmann or kth
    ss = strsplit(stip_data_test{ii}.video,'_');
    Yt(ii) = find(strcmp(act_list, ss{2}));

    %%% if HMDB51
%     Yt(ii) = find(strcmp(act_list, stip_data_train{ii}.video));

%     Xt(ii,:) = Encoding(stip_data_test{ii}.features(:,8:end),codebook);
    %%% only HOG and HOF are features.
    Xt(ii,:) = Encoding(stip_data_test{ii}.features(:,10:end),codebook);
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

opt.nFold = 10; %%% rochester and weizmann, 5-fold cv; KTH 10-foldsave
opt.kernel = 'linear';
Xtrain = CCV_normalize(Xs,1);
Xtest = CCV_normalize(Xt,1);
[acc, prob_estimates, bestmodel, class_label, meta_res]...
        =Fu_direct_SVM2(Xtrain, Xtest, Ys,Yt,opt);

end
