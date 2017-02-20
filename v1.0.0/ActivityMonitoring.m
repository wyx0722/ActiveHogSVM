function ActivityMonitoring(dataset,activity,subject,trial, method)
%%% we monitor the activities via the motion energy in each bounding box
%%% - within each bounding box, the motion energy is described by mean and
%%% variance considering all pixels
%%% - to compare two frames (two 3D volumes), we use chi-square distance
%%% see I.Laptev et al., Learning Realistic Human Actions from Movies


%%% dataset and parameter config
ant_path = ['annotation/',dataset];
info = importdata([ant_path,'/DataStructure.mat']);
video_path = info.dataset_path;
n_subs = info.num_subjects;
n_acts = info.num_activities;
n_trials = info.num_trials;
act_list = importdata([ant_path,'/activity_list.txt']);
fprintf('Dataset: %s\n',dataset);


% %%% read video and annotation
% video_file_name = sprintf(info.file_format,activity,subject,trial);
% fprintf('- processing video: %s \n',video_file_name);
% antDir = [ant_path,'/',video_file_name];
% video = [video_path,'/',video_file_name];
% ant_bb = importdata([antDir,'/rect.mat']);
% fprintf('-- compute optical flow..\n');


%%% read video and read model
addpath(genpath('exemplarsvm_lib'));
addpath(genpath('poselets_matlab_april2013'));
mm = load(sprintf('annotation/src_annotation_RochesterADL/esvm_head_2017.2.13/rochester_head_model/esvm_head_%i/models/head-svm-stripped.mat',subject)); %% the model when s1 is excluded
video_file_name = sprintf(info.file_format,activity,subject,trial);
fprintf('- processing video: %s \n',video_file_name);
video = [video_path,'/',video_file_name];

vocabularies_head = importdata(sprintf('vocabularies_head_subject_%i.mat',subject);
vocabularies_torso = importdata(sprintf('vocabularies_torso_subject_%i.mat',subject);
vocabularies_person = importdata(sprintf('vocabularies_person_subject_%i.mat',subject);





%%% compute optical flow and extract statistics of motion energy
kk = 1;
vv = VideoReader(video);


L = 15; %% consider 15 frames in the bounding box
ii = 1;
tsm = [];
motion_energy_pre = {};
feature_set_pre = {};
dist = [];
figure;
while hasFrame(vv) 
    frame = readFrame(vv);
    frame = imresize(frame,0.5);
    subplot(1,2,1);imshow(frame);drawnow;
    if mod(ii,20) == 0
%         rect_head = round(ant_bb{kk}.head);
%         rect_torso = round(ant_bb{kk}.torso);
%         rect_person = round(ant_bb{kk}.person);
        %%% detect body parts and gives bounding boxes
        [rect_head,~] = head_detection(frame,mm.models);
        [rect_person,rect_torso,~,~] = body_detection(frame);
        patch_head = [];
        patch_torso = [];
        patch_person = [];
        feature_set = {};
     
        motion_energy = InitMotionEnergy();
        flow_head = opticalFlowFarneback;
        flow_torso = opticalFlowFarneback;
        flow_person = opticalFlowFarneback;

     
        tsm = ii;
        kk = kk+1;
    end  
    
    
    switch methed
        case 'bag-of-feature'
           if ~isempty(tsm)
            if ((ii-tsm)<=L)
                frame = rgb2gray(frame);
                subplot(1,2,1);
                rectangle('Position',rect_head,'EdgeColor','red','LineWidth',2);
                rectangle('Position',rect_person,'EdgeColor','yellow','LineWidth',2);
                rectangle('Position',rect_torso,'EdgeColor','blue','LineWidth',2);
                drawnow;
                patch_head = cat(3,patch_head,imcrop(frame,rect_head));
                patch_torso = cat(3,patch_torso,imcrop(frame,rect_torso));
                patch_person = cat(3,patch_person,imcrop(frame,rect_person));

            end
            end

            if (ii-tsm)== L+1
                %%% computer flow, dense sample the 3D patches, extract features.
                [flowx_head, flowy_head] = FlowExtractionFromImgSeq(patch_head);
                [flowx_torso, flowy_torso] = FlowExtractionFromImgSeq(patch_torso);
                [flowx_person, flowy_person] = FlowExtractionFromImgSeq(patch_person);
                
                feature_head = ExtractMBH(flowx_head,flowy_head);
                feature_torso = ExtractMBH(flowx_torso,flowy_torso);
                feature_person = ExtractMBH(flowx_person,flowy_person);

                %%% feature encoding using learned vocabularies
                feature_set.head = Encoding(feature_head,vocabularies_head);
                feature_set.torso = Encoding(feature_torso,vocabularies_torso);
                feature_set.person = Encoding(feature_person,vocabularies_person);

                %%% evaluate the Chi-Square distance
                dist1 = Chi2Distance2(feature_set_pre, feature_set);
                dist = [dist;dist1];

                %%% visualize the curve
                subplot(1,2,2);plot(dist);
                drawnow;
                feature_set_pre = feature_set;
            end
        


        case 'MotionEnergy'
            if ~isempty(tsm)
            if ((ii-tsm)<=L)
                frame = rgb2gray(frame);
                subplot(1,2,1);
                rectangle('Position',rect_head,'EdgeColor','red','LineWidth',2);
                rectangle('Position',rect_person,'EdgeColor','yellow','LineWidth',2);
                rectangle('Position',rect_torso,'EdgeColor','blue','LineWidth',2);
                drawnow;
                patch_head = imcrop(frame,rect_head);
                patch_torso = imcrop(frame,rect_torso);
                patch_person = imcrop(frame,rect_person);

                flow_head = estimateFlow(opticFlow_head,patch_head);
                flow_torso = estimateFlow(opticFlow_torso,patch_torso);
                flow_person = estimateFlow(opticFlow_person,patch_person);
                motion_energy.head.mean  = [motion_energy.head.mean; mean(flow_head.Magnitude(:))];
        %         motion_energy.head.std  = [motion_energy.head.std; std(flow_head.Magnitude(:))];

                motion_energy.torso.mean  = [motion_energy.torso.mean; mean(flow_torso.Magnitude(:))];
        %         motion_energy.torso.std  = [motion_energy.torso.std; std(flow_torso.Magnitude(:))];

                motion_energy.person.mean  = [motion_energy.person.mean; mean(flow_person.Magnitude(:))];
        %         motion_energy.person.std  = [motion_energy.person.std; std(flow_person.Magnitude(:))];
            end
            end

            if (ii-tsm)== L+1
                %%% first excluding the first element and normalize the histogram
                fnames = fieldnames(motion_energy);
                for nnn = 1:length(fnames) 
                    motion_energy.(fnames{nnn}).mean(1) = [];
        %             motion_energy.(fnames{nnn}).std(1) = [];
                    motion_energy.(fnames{nnn}).mean = motion_energy.(fnames{nnn}).mean/sum(motion_energy.(fnames{nnn}).mean);
        %             motion_energy.(fnames{nnn}).std = motion_energy.(fnames{nnn}).std/sum(motion_energy.(fnames{nnn}).std);
                end

                dist1 = Chi2Distance(motion_energy_pre, motion_energy);
                dist = [dist;dist1];

                %%% visualize the curve
                subplot(1,2,2);plot(dist);
                drawnow;
                motion_energy_pre = motion_energy;
            end
        






        otherwise
            error('no other method');
    end
            
    ii = ii+1;
end
    
end





function dist = Chi2Distance(motion_energy_pre,motion_energy)

if isempty(motion_energy_pre)
    dist = 0;
    return;
end

%%% 
dd = 0;
fnames = fieldnames(motion_energy);
for nn = 1:length(fnames)
    x1 = motion_energy_pre.(fnames{nn}).mean;
    x2 = motion_energy.(fnames{nn}).mean;
    dd = dd+sum((x2-x1).^2./(x1+x2))/2;
    
%     x1 = motion_energy_pre.(fnames{nn}).std;
%     x2 = motion_energy.(fnames{nn}).std;
%     dd = dd+sum((x2-x1).^2./(x1+x2))/2;
end
dist = dd;

end


function dist = Chi2Distance2(feature_set_pre,feature_set)

if isempty(feature_set_pre)
    dist = 0;
    return;
end

%%% 
dd = 0;
fnames = fieldnames(feature_set);
for nn = 1:length(fnames)
    x1 = feature_set_pre.(fnames{nn});
    x2 = feature_set.(fnames{nn});
    dd = dd+sum((x2-x1).^2./(x1+x2))/2;
    
%     x1 = motion_energy_pre.(fnames{nn}).std;
%     x2 = motion_energy.(fnames{nn}).std;
%     dd = dd+sum((x2-x1).^2./(x1+x2))/2;
end
dist = dd;

end


function me = InitMotionEnergy()
me.head.mean = [];
me.head.std = [];

me.torso.mean = [];
me.torso.std = [];

me.person.mean = [];
me.person.std = [];

end




function [rect_head,score_head] = head_detection(img,models,rect_person)

test_params = esvm_get_default_params;
test_params.detect_min_scale = 0.5;
test_params.detect_exemplar_nms_os_threshold = 0.5;
test_params.detect_max_windows_per_exemplar = 1;
test_set_name = 'testset';
test_params.detect_levels_per_octave = 2;


%%% constrain the head detector search space using the bbox of person
margin = 30;
rect_margin = [rect_person(1:2)-margin, rect_person(3:4)+margin];
img = imcrop(img,rect_margin);

Ipos_test{1} = img;
test_grid = esvm_detect_imageset(Ipos_test(1), models, test_params, test_set_name);
test_struct = esvm_pool_exemplar_dets(test_grid, models, [], test_params);

rect_head = test_struct.final_boxes{1}(1,1:4);
score_head = test_struct.final_boxes{1}(1,12);

%%% convert rect to matlab format[xmin ymin width height]
rect_head =  [rect_head(1:2) rect_head(3:4)-rect_head(1:2)];


%%% map the head bbox to the original image
rect_head = rect_head + [rect_margin(1:2) 0 0];
end



function [rect_person,rect_torso,score_person,score_torso] = body_detection(img)

global config;
config=init;

% Choose the category here
category = 'person';

data_root = [config.DATA_DIR '/' category];

disp(['Running on ' category]);

faster_detection = true;  % Set this to false to run slower but higher quality
interactive_visualization = false; % Enable browsing the results
enable_bigq = true; % enables context poselets

if faster_detection
%     disp('Using parameters optimized for speed over accuracy.');
    config.DETECTION_IMG_MIN_NUM_PIX = 500^2;  % if the number of pixels in a detection image is < DETECTION_IMG_SIDE^2, scales up the image to meet that threshold
    config.DETECTION_IMG_MAX_NUM_PIX = 750^2;
    config.PYRAMID_SCALE_RATIO = 1.5;
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

% im1.image_file{1}=[data_root '/test.jpg'];
% img = imread(im1.image_file{1});
% im1.image_file{1} ='/home/zhang/workspace/ActiveHogSVM/annotation/Dataset_RochesterADL/answerPhoneS3R1.avi/frame_5.png'; 
% img = imread(im1.image_file{1});


[bounds_predictions,poselet_hits,torso_predictions]=detect_objects_in_image(img,model,config);

if interactive_visualization && (~exist('poselet_patches','var') || ~exist('fg_masks','var'))
    disp('Interactive visualization not supported for this category');
    interactive_visualization=false;
end

% display_thresh=0; % detection rate vs false positive rate threshold
% imshow(img);

scores = bounds_predictions.score;
[~,idx] = sort(scores,'descend');
% bounds_predictions.select(idx(1)).draw_bounds;
% torso_predictions.select(idx(1)).draw_bounds('blue');
rect_person = bounds_predictions.select(idx(1)).bounds;
rect_torso = torso_predictions.select(idx(1)).bounds;
score_person = scores(idx(1));
score_torso = score_person;


end







function [flowx,flowy] = FlowExtractionFromImgSeq(imgseq)
%%% this function estimate flows using Farneback method
%%% we focus on the motion information, thus convert RGB to Gray
%%% notice that nt(imgseq) = nt(flow)+1, we need the previous frame.
[ny, nx, nt] = size(imgseq);
flowx = [];
flowy = [];

opticFlow = opticalFlowFarneback;
for ll = 1:nt
        
  frame = imgseq(:,:,ll);
  flow = estimateFlow(opticFlow,frame);
  flowx = cat(3,flowx,flow.Vx);
  flowy = cat(3,flowy,flow.Vy);
end

%%% exclude the flow based on a black image.
flowx = flowx(:,:,2:end);
flowy = flowy(:,:,2:end);
end








function mbh = ExtractMBH(cube_x,cube_y)

%%% use the suggested parameters in the following paper:
%%% H.Wang,A.Klaeser, C.Schmid, C.Liu DenseTrajectories and Motion Boundary
%%% Descriptors for Action Recognition

%%% in the cubex and cubey. (1) We first densely sample points at every W
%%% pixel. (2)Then surrounding each pixel, we create a 3D block of size
%%% N*N*15. (3) Each 3D block is further divided into several cells,
%%% considering the dynamic structure. Each block is divided into ns*ns*nt cells. (4) The
%%% N*N*15 block is represented by concatenating the features of all
%%% cells. (5) Here we dont consider multiple spatio pyramid, since
%%% bodypart detectors already did that. 
N = 32; ns = 2; nt = 3; W = 15; % For efficiency, we changed the parameter to get fewer features than training. 

[NY,NX,NT] = size(cube_x);
mbh = [];

%%% extract the block based on dense sampling scheme
n_block_x = floor((NX-N)/W);
n_block_y = floor((NY-N)/W);
for ii = 1:n_block_x
    for jj = 1:n_block_y
        xx = N/2+(ii)*W;
        yy = N/2+(jj)*W;
        fea_vec = ExtractMBH_block(cube_x((yy-N/2):(yy+N/2-1),(xx-N/2):(xx+N/2-1),:),...
                                   cube_y((yy-N/2):(yy+N/2-1),(xx-N/2):(xx+N/2-1),:), ns,nt);
        mbh = [mbh;fea_vec];
    end
end

end


function feature = ExtractMBH_block(cube_x,cube_y,ns,nt)
%%% this function extract the feature vector of each block N*N*L
%%% this block is divided to ns*ns*nt cells
%%% we directly extract HOG from each flow channel to composite MBH
[ny,nx,l] = size(cube_x);
cell_size = [ny,nx,l]./[ns,ns,nt];
feature = [];

for ll = 1:nt
    tt = (ll-1)*nt+1;
    cellx = cube_x( :,:, tt:tt+cell_size(3)-1);
    celly = cube_y( :,:, tt:tt+cell_size(3)-1);
                                               
    mbhx = zeros(ns,ns,31);
    mbhy = zeros(ns,ns,31);
    for tt = 1:size(cellx,3)
        mbhx = mbhx+ hog_grayscale(double(cellx(:,:,tt)),cell_size(1));
        mbhy = mbhy+ hog_grayscale(double(celly(:,:,tt)),cell_size(1));
    end
    feature = [feature; [mbhx(:);mbhy(:)]];
                                                                                                                   
end
feature = feature';
end


