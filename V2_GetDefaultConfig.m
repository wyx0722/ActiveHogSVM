function option = V2_GetDefaultConfig()

%% poselets
poselet_path = 'poselets_matlab_april2013/detector/poselet_detection';
addpath(genpath(poselet_path));
option.poselet.config=init(poselet_path);
option.poselet.category = 'person';

data_root = [option.poselet.config.DATA_DIR '/' option.poselet.category];

option.poselet.faster_detection = true;  % Set this to false to run slower but higher quality
option.poselet.interactive_visualization = false; % Enable browsing the results
option.poselet.enable_bigq = true; % enables context poselets
if option.poselet.faster_detection
%     disp('Using parameters optimized for speed over accuracy.');
    option.poselet.config.DETECTION_IMG_MIN_NUM_PIX = 500^2;  % if the number of pixels in a detection image is < DETECTION_IMG_SIDE^2, scales up the image to meet that threshold
    option.poselet.config.DETECTION_IMG_MAX_NUM_PIX = 750^2;
    option.poselet.config.PYRAMID_SCALE_RATIO = 2;
end

% Loads the SVMs for each poselet and the Hough voting params

load([data_root '/model.mat']); % model
if exist('output','var')
    option.poselet.model=output; clear output;
end
if ~option.poselet.enable_bigq
   option.poselet.model =rmfield(model,'bigq_weights');
   option.poselet.model =rmfield(model,'bigq_logit_coef');
   disp('Poselet Config: Context is disabled.');
end

option.poselet.is_visualization = false;
option.poselet.is_save_image = false;
option.poselet.to_imgset = true;
option.poselet.subsampling_factor = 20;
option.poselet.frame_scaling = 0.5;




% if ~option.poselet.enable_bigq || option.poselet.faster_detection
%    disp('*******************************************************');
%    disp('* NOTE: The code is running in faster but suboptimal mode.');
%    disp('*       Before reporting comparison results, set faster_detection=false; enable_bigq=true;');
%    disp('*******************************************************');
% end
%% files io
%%% specify the dataset path
timer = datestr(fix(clock),'yyyy-mm-dd-HH-MM');
option.fileIO.time = timer;
option.fileIO.dataset_path = sprintf('~/Videos/Dataset_%s',dataset);
option.fileIO.dataset_name = dataset;

%%% read the action_list
switch dataset
    case 'RochesterADL'
        act_list = importdata('annotation/Dataset_RochesterADL/activity_list.txt');
        option.fileIO.stip_file_version = '2.0'; 
    case 'Weizmann'
        act_list = {'bend','jack','jump','pjump','run','side','skip','walk','wave1','wave2'};
        option.fileIO.subject_list = {'daria','denis','eli','ido','ira','lena','lyova','moshe','shahar'};
        option.fileIO.stip_file_version = '2.0'; 
    case 'KTH'
        act_list = {'boxing','handclapping','handwaving','jogging','running','walking'};
        option.fileIO.stip_file_version = '2.0'; 
    case 'HMDB51'
        dataset_path = option.fileIO.dataset_path;
        split_path = [dataset_path '/testTrainMulti_7030_splits'];
        aa = dir(dataset_path);
        act_list = arrayfun( @(x) x.name, aa(3:end),'UniformOutput',false );
        act_list(strcmp(act_list,'testTrainMulti_7030_splits'))=[];
        act_list(strcmp(act_list,'uncompress.sh'))=[];
        option.fileIO.stip_file_version = '1.0'; 
    otherwise
        error('no other datasets so far...');
end
option.fileIO.act_list = act_list;
%%% normally it is 2.0. But HMBD51 used 1.0 version.

%%% the file to store all results: codebook,svm and eval results.
option.fileIO.eval_res_file = sprintf('%s_EvaluationResults_%s.mat',dataset,timer);
option.fileIO.option_file = sprintf('%s_option_%s.mat',dataset,timer);