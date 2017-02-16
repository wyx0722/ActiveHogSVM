function features = collect_features(dataset, bodypart, subject,activity,tt)


%%% dataset and parameter config
ant_path = ['annotation/',dataset];
info = importdata([ant_path,'/DataStructure.mat']);
video_path = info.dataset_path;



%%% video to image sequence config
resize_factor = 0.5;

%%% spatio-temporal cube config
L = 15; %% temporal length of the 3D cube

%%% add path of hog grayscale image
addpath(genpath('hog_mex'));
n_trials = 3;

features = [];

tic
%%% read video frames and annotated bounding boxes

video_file_name = sprintf(info.file_format,activity,subject,tt);
fprintf('- processing video: %s \n',video_file_name);
antDir = [ant_path,'/',video_file_name];
video = [video_path,'/',video_file_name];
ant_bb = importdata([antDir,'/rect.mat']);
fprintf('-- compute optical flow..\n');
imgseq = FrameExtraction(video,resize_factor);


%%% extract flow features MBH
fprintf('--extract mbh features in the bounding box..\n');
kk = 1;
for ii = 1:size(imgseq,3)-L
    cube = [];
%             cubey = [];
    if mod(ii,info.sampling_rate) == 0
        rect = round(ant_bb{kk}.(bodypart));
        xmin = rect(1);
        xmax = rect(1)+rect(3);
        ymin = rect(2);
        ymax = rect(2)+rect(4);
        cube(:,:,1:L+1) = imgseq(ymin:ymax,xmin:xmax,(ii-1):(ii+L-1));
        [cubex,cubey] = FlowExtractionFromImgSeq(cube);

        %%% extract the feature here, where we perform dense
        %%% sampling
        mbh = ExtractMBH(cubex,cubey); %% the output is N*D matrix, rows are samples, cols are features.

        %%% todo stack the feature vector to the pool
        features = [features;mbh];

        kk = kk+1;
    end
end

timer = toc;
fprintf('--time cost = %f seconds\n',timer);



end



function imgseq = FrameExtraction(video,resize_factor)
%%% this function extract all frames from video
%%% we focus on the motion information later, thus convert RGB to Gray

vv = VideoReader(video);
imgseq = [];

while hasFrame(vv)
    
    frame = readFrame(vv);    
    frame = imresize(frame,resize_factor);
    frame = rgb2gray(frame);
    imgseq = cat(3,imgseq,frame);
    
end

end




function [flowx,flowy] = FlowExtraction(video,resize_factor)
%%% this function estimate flows using Farneback method
%%% we focus on the motion information, thus convert RGB to Gray

vv = VideoReader(video);
flowx = [];
flowy = [];

opticFlow = opticalFlowFarneback;
while hasFrame(vv)
    
    frame = readFrame(vv);    
    frame = imresize(frame,resize_factor);
    frame = rgb2gray(frame);
    flow = estimateFlow(opticFlow,frame);
    flowx = cat(3,flowx,flow.Vx);
    flowy = cat(3,flowy,flow.Vy);
    
end

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
N = 32; ns = 2; nt = 3; W = 20; %%% for head and torso, W=5; for person, W=20;

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
    tt = (ll-1)*cell_size(3)+1;
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







