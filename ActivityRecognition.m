function model = ActivityRecognition_train(dataset,subject)
%%% we train the activities models using part-based bag-of-features
%%% we optimize the hyper-parameters of the SVMs via cross-validation and grid search
%%% Input: the dataset and the subject to exclude. 
%%% Output: the trained model 

%%% dataset and parameter config
ant_path = ['annotation/',dataset];
info = importdata([ant_path,'/DataStructure.mat']);
video_path = info.dataset_path;
n_subs = info.num_subjects;
n_acts = info.num_activities;
n_trials = info.num_trials;
act_list = importdata([ant_path,'/activity_list.txt']);
fprintf('Dataset: %s\n',dataset);

%%% add path for chi-square svm learning
addpath(genpath('internal/'));
addpath(genpath('libsvm/matlab'));
% %%% read video and annotation
% video_file_name = sprintf(info.file_format,activity,subject,trial);
% fprintf('- processing video: %s \n',video_file_name);
% antDir = [ant_path,'/',video_file_name];
% video = [video_path,'/',video_file_name];
% ant_bb = importdata([antDir,'/rect.mat']);
% fprintf('-- compute optical flow..\n');


%%% read the learned vocabularies, which already excluded the test subject. 
vocabularies_head = importdata(sprintf('vocabularies_Rochester_S%i_head.mat',subject);
vocabularies_torso = importdata(sprintf('vocabularies_Rochester_S%i_torso.mat',subject);
vocabularies_person = importdata(sprintf('vocabularies_Rochester_S%i_person.mat',subject);

%%% read extracted dense MBH features and create video features based on a temporal pyramid.
features = InitFeatureSet(act_list);
X= {};
Y = [];
idx = 1;
for aa = 1:n_acts
    for ss = 1:n_subs
        if ss==subject
            continue;
        end
        for tt = 1:n_trials
            fea_head = import(sprintf('DenseMBH_Rochester/denseMBH_%sS%iR%i_head.mat',act_list{aa},ss,tt));
            N = size(fea_head,1);
            X{idx}.head = [Encoding(fea_head,vocabularies_head);
                      Encoding(fea_head(1:round(N/2),:),vocabularies_head);
                      Encoding(fea_head(round(N/2)+1:end,:),vocabularies_head);
                      Encoding(fea_head(1:round(N/3),:),vocabularies_head);
                      Encoding(fea_head(round(N/3)+1 : round(2*N/3),:),vocabularies_head);
                      Encoding(fea_head(round(2*N/3)+1:end,:),vocabularies_head) ];
           
           
            fea_torso = import(sprintf('DenseMBH_Rochester/denseMBH_%sS%iR%i_torso.mat',act_list{aa},ss,tt));
            N = size(fea_torso,1);
            X{idx}.torso = [Encoding(fea_torso,vocabularies_torso);
                      Encoding(fea_torso(1:round(N/2),:),vocabularies_torso);
                      Encoding(fea_torso(round(N/2)+1:end,:),vocabularies_torso);
                      Encoding(fea_torso(1:round(N/3),:),vocabularies_torso);
                      Encoding(fea_torso(round(N/3)+1 : round(2*N/3),:),vocabularies_torso);
                      Encoding(fea_torso(round(2*N/3)+1:end,:),vocabularies_torso) ];

            fea_person = import(sprintf('DenseMBH_Rochester/denseMBH_%sS%iR%i_person.mat',act_list{aa},ss,tt));
            N = size(fea_person,1);
            X{idx}.person = [Encoding(fea_person,vocabularies_person);
                      Encoding(fea_person(1:round(N/2),:),vocabularies_person);
                      Encoding(fea_person(round(N/2)+1:end,:),vocabularies_person);
                      Encoding(fea_person(1:round(N/3),:),vocabularies_person);
                      Encoding(fea_person(round(N/3)+1 : round(2*N/3),:),vocabularies_person);
                      Encoding(fea_person(round(2*N/3)+1:end,:),vocabularies_person) ];

                
            Y(idx) = aa;
            idx = idx+1;

        end
    end

end



%%% train a multi-class svm and optimize the hyper-parameters
%%% todo
model = TrainSVM(X,Y);

end








function model = TrainSVM(X,Y)
%%% X is a struct containing feature vectors in a context hierarchy.
%%% Y is the action label.
Xtrain = [];
Ytrain = [];

N = length(Y);
for i = 1:N
part = fieldnames(X{i});













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


function me = InitFeatureSet(act_list)
me = {};
for ii = 1:length(act_list)
    me.(act_list{ii}).head = [];
    me.(act_list{ii}).torso = [];
    me.(act_list{ii}).person = [];
end

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


