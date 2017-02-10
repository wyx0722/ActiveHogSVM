%% function - poselet_featuring
function [poselet_hits_list]=my_poselet_featuring_image(filepath, config, is_saving_img,option)

if nargin == 2
    is_saving_img == false;
end

%%% setup poselet detectors--------------------------------------------------
disp('===============================================');
disp('Poselet detectors are directly from the following source:');
disp( 'Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.');
disp( 'This code is distributed with a non-commercial research license.');
disp( 'Please see the license file license.txt included in the source directory.');
disp('===============================================');
disp('This code is modified by yan.zhang@uni-ulm.de');
disp('===============================================');


category = 'person';
data_root = [config.DATA_DIR '/' category];
disp(['Running on ' category]);
faster_detection = true;  % Set this to false to run slower but higher quality
interactive_visualization = true; % Enable browsing the results
enable_bigq = false; % enables context poselets
if faster_detection
    disp('Using parameters optimized for speed over accuracy.');
    config.DETECTION_IMG_MIN_NUM_PIX = 500^2;  % if the number of pixels in a detection image is < DETECTION_IMG_SIDE^2, scales up the image to meet that threshold
    config.DETECTION_IMG_MAX_NUM_PIX = 750^2;
    config.PYRAMID_SCALE_RATIO = 2;
end


% Loads the SVMs for each poselet and the Hough voting params
clear output poselet_patches fg_masks;
load([data_root '/model.mat']); % model
if exist('output','var')
    model=output; clear output;
end
if ~enable_bigq
   model =rmfield(model,'bigq_weights');
   model =rmfield(model,'bigq_logit_coef');
   disp('Context is disabled.');
end
if ~enable_bigq || faster_detection
   disp('*******************************************************');
   disp('* NOTE: The code is running in faster but suboptimal mode.');
   disp('*       Before reporting comparison results, set faster_detection=false; enable_bigq=true;');
   disp('*******************************************************');
end
%%% setup poselet detectors-----------------------------------------------end



%%%----------------read image--------------------------------------

img = imread(filepath);
img = imresize(img,0.5);
img = imgaussfilt(img,1.0);

% retain all poselets and show the poselets and their q-scores
poselet_hits_list=activate_all_poselets_in_image(img,model,config,option);

% NEW Feature: consider the Q-score
if isfield(model,'bigq_weights')
%   fprintf('Big Q...');
%    start_time=clock;
   hyps=[model.hough_votes.hyp];
   [features,contrib_hits] = get_context_features_in_image(hyps,poselet_hits_list,config);
   poselet_hits_list.src_idx = contrib_hits';
   poselet_hits_list.score = sum(features.*model.bigq_weights(poselet_hits_list.poselet_id,1:(end-1)),2) + model.bigq_weights(poselet_hits_list.poselet_id,end);
   poselet_hits_list.score = -poselet_hits_list.score.*model.bigq_logit_coef(poselet_hits_list.poselet_id,1)-model.bigq_logit_coef(poselet_hits_list.poselet_id,2);
   poselet_hits_list.score = 1./(1+exp(-poselet_hits_list.score));
%   fprintf('Done in %4.2f secs.\n',etime(clock,start_time));
end

% visualization using dots
fig1=figure;image(img);truesize;hold on;
display_thresh=-inf;  % for visualize purpose, we can remove low-confidence activations
poselet_hits_list.select(poselet_hits_list.score>display_thresh).draw_points;
colorbar;
fig2=figure;bar(poselet_hits_list.poselet_id_all,poselet_hits_list.score);
xlim([0,poselet_hits_list.n_poselets]);

if is_saving_img == true
    print(fig1,['activation_poselet'],'-dpng');
    print(fig2,['score_poselet'],'-dpng');
end
  




end
