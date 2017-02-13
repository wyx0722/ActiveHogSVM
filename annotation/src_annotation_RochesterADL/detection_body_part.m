function rect = detection_body_part(video,head_models)


workingDir=...
    ['/home/yzhang/workspace/ActivityRecognition/annotation/Dataset_RochesterADL/',...
    video];
addpath(genpath('exemplarsvm_lib'));
addpath(genpath('poselets_matlab_april2013'));

imageNames = dir(fullfile(workingDir,'*.png'));
imageNames = {imageNames.name};
N = length(imageNames);
rect = {};
for i = 1:N
    image_file_name = [workingDir,'/',imageNames{i}];
    img = imread(image_file_name);
    
    tic;
    fprintf('-- esvm head detection...\n');
    [rect_head,score_head] = head_detection(img,head_models);
    
    fprintf('-- poselet body detection...\n');
    [rect_person,rect_torso,score_person,~] = body_detection(img);
    toc;
    
    rect{i}.image_file_name = image_file_name;
    rect{i}.head = [rect_head(1:2),rect_head(3:4)-rect_head(1:2)];
    rect{i}.person = rect_person;
    rect{i}.torso = rect_torso;
    figure(1);hh=imshow(img);hold on;
    rectangle('Position',rect{i}.head,'EdgeColor','red','LineWidth',2);
    rectangle('Position',rect{i}.person,'EdgeColor','yellow','LineWidth',2);
    rectangle('Position',rect{i}.torso,'EdgeColor','blue','LineWidth',2);
    drawnow;
    %%% automatic stops according to detection scores
    thresh_head_dec = -0.7;
    thresh_person_dec = 1;
    score_head
    score_person
    if score_person <= thresh_person_dec || score_head <= thresh_head_dec
        xx = input('Is the detection correct?:(yes-1,no-0)');
        while xx == 0
            part = input('which part is wrong?:','s');
            switch part
                case 'head'
                    rect{i}.head = getrect;
                    rectangle('Position',rect{i}.head,'EdgeColor','red','LineWidth',2,...
                        'LineStyle','--');
                case 'person'
                    rect{i}.person = getrect;
                    rectangle('Position',rect{i}.person,'EdgeColor','yellow','LineWidth',2,...
                        'LineStyle','--');

                case 'torso'
                    rect{i}.torso = getrect;
                    rectangle('Position',rect{i}.torso,'EdgeColor','blue','LineWidth',2,...
                        'LineStyle','--');

                otherwise
                    error('no other option.');
            end
            xx = input ('all right?:(yes-1, no-0)');
        end
    end
        
end

save([workingDir,'/rect.mat'],'rect');


end



function [rect_head,score_head] = head_detection(img,models)

test_params = esvm_get_default_params;
test_params.detect_min_scale = 0.5;
test_params.detect_levels_per_octave = 1;
test_params.detect_exemplar_nms_os_threshold = 0.5;
test_params.detect_max_windows_per_exemplar = 3;
test_set_name = 'testset';
test_params.detect_levels_per_octave = 3;

Ipos_test{1} = img;
test_grid = esvm_detect_imageset(Ipos_test(1), models, test_params, test_set_name);
test_struct = esvm_pool_exemplar_dets(test_grid, models, [], test_params);

rect_head = test_struct.final_boxes{1}(1,1:4);
score_head = test_struct.final_boxes{1}(1,12);

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
    config.PYRAMID_SCALE_RATIO = 1.31;
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