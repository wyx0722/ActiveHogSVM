%% function - poselet_featuring
function [poselet_hits_list,img_set]=my_poselet_featuring_video(filepath, config, ...
    is_visualization, is_save_image, to_imgseq, subsampling_factor,frame_scaling, option)

if nargin == 2
    is_save_image = false;
    is_visualization = false;
    to_imgseq = false;
    subsampling_factor = 1;
    frame_scaling = 1;
end

%%% setup poselet detectors--------------------------------------------------
% disp('===============================================');
% disp('Poselet detectors are directly from the following source:');
% disp( 'Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.');
% disp( 'This code is distributed with a non-commercial research license.');
% disp( 'Please see the license file license.txt included in the source directory.');
% disp('===============================================');
% disp('This code is modified by yan.zhang@uni-ulm.de');
% disp('===============================================');


category = 'person';
data_root = [config.DATA_DIR '/' category];
disp(['Running on ' category]);
faster_detection = true;  % Set this to false to run slower but higher quality
interactive_visualization = true; % Enable browsing the results
enable_bigq = true; % enables context poselets
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
% if ~enable_bigq || faster_detection
%    disp('*******************************************************');
%    disp('* NOTE: The code is running in faster but suboptimal mode.');
%    disp('*       Before reporting comparison results, set faster_detection=false; enable_bigq=true;');
%    disp('*******************************************************');
% end
%%% setup poselet detectors-----------------------------------------------end



%%%----------------read video--------------------------------------
vv = VideoReader(filepath);
poselet_hits_list = {};
img_set = {};
i = 1;
fprintf(' - processing video:%s\n',filepath);
while hasFrame(vv)
    frame = readFrame(vv); 
    img = imgaussfilt(imresize(frame,frame_scaling),0.5);
    
    %save images to workspace
    if to_imgseq
        img_set{i} = img;
    end
    
    if ~mod(i,subsampling_factor)
        fprintf('-- #frame = %d\n',i);
        
        % retain all poselets and show the poselets and their scores
        poselet_hits_list{i}=activate_all_poselets_in_image(img,model,config, option);
    %     fprintf('#feature = %d\n', poselet_hits_list{i}.n_poselets);
        % NEW Feature: consider the Q-score
        if isfield(model,'bigq_weights')
        %   fprintf('Big Q...');
        %    start_time=clock;
           hyps=[model.hough_votes.hyp];
           [features,contrib_hits] = get_context_features_in_image(hyps,poselet_hits_list{i},config);
           poselet_hits_list{i}.src_idx = contrib_hits';
           poselet_hits_list{i}.score = sum(features.*model.bigq_weights(poselet_hits_list{i}.poselet_id,1:(end-1)),2) + model.bigq_weights(poselet_hits_list{i}.poselet_id,end);
           poselet_hits_list{i}.score = -poselet_hits_list{i}.score.*model.bigq_logit_coef(poselet_hits_list{i}.poselet_id,1)-model.bigq_logit_coef(poselet_hits_list{i}.poselet_id,2);
           poselet_hits_list{i}.score = 1./(1+exp(-poselet_hits_list{i}.score));
        %   fprintf('Done in %4.2f secs.\n',etime(clock,start_time));
        end
        % visualization using dots
        if is_visualization & ~isempty(poselet_hits_list{i}.score)
            fig1=figure(1);image(img);hold on;
            display_thresh=0.00;  % for visualize purpose, we can remove low-confidence activations
            poselet_hits_list{i}.select(poselet_hits_list{i}.score>display_thresh).draw_points;
            fig2=figure(2);bar(poselet_hits_list{i}.poselet_id_all,poselet_hits_list{i}.score,0.3);
            xlim([0,poselet_hits_list{i}.n_poselets+1])
            ylim([0,1]);
            if is_save_image == true
                print(fig1,['activation_poselet_',num2str(i)],'-dpng');
                print(fig2,['score_poselet_',num2str(i)],'-dpng');
            end
            pause;
            clf(fig1);
            clf(fig2);   
        end

    end
        
    i = i+1;
    
    
end
    


end
