function ActivityMonitoring(dataset,activity,subject,trial)
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


%%% read video and annotation
video_file_name = sprintf(info.file_format,activity,subject,trial);
fprintf('- processing video: %s \n',video_file_name);
antDir = [ant_path,'/',video_file_name];
video = [video_path,'/',video_file_name];
ant_bb = importdata([antDir,'/rect.mat']);
fprintf('-- compute optical flow..\n');

%%% compute optical flow and extract statistics of motion energy
kk = 1;
vv = VideoReader(video);
opticFlow = opticalFlowFarneback;
L = 15; %% consider 15 frames in the bounding box
ii = 1;
motion_energy = {};
motion_energy_pre = {};
while hasFrame(vv) 
    frame = readFrame(vv);
    
    if mod(ii,info.sampling_rate) == 0
        rect_head = round(ant_bb{kk}.head);
        rect_torso = round(ant_bb{kk}.torso);
        rect_person = round(ant_bb{kk}.person);
        tsm = ii;
    end  
    if (ii-tsm)<=L+1


        frame = rgb2gray(imresize(frame,0.5));
        patch_head = imcrop(frame,rect_head);
        patch_torso = imcrop(frame,rect_torso);
        patch_person = imcrop(frame,rect_person);

        flow_head = estimateFlow(opticFlow,patch_head);
        flow_torso = estimateFlow(opticFlow,patch_torso);
        flow_person = estimateFlow(opticFlow,patch_person);
        motion_energy.head.mean  = [motion_energy.head.mean; mean(flow_head.magnitude(:))];
        motion_energy.head.std  = [motion_energy.head.std; std(flow_head.magnitude(:))];

        motion_energy.torso.mean  = [motion_energy.torso.mean; mean(flow_torso.magnitude(:))];
        motion_energy.torso.std  = [motion_energy.torso.std; std(flow_torso.magnitude(:))];

        motion_energy.person.mean  = [motion_energy.person.mean; mean(flow_person.magnitude(:))];
        motion_energy.person.std  = [motion_energy.person.std; std(flow_person.magnitude(:))];
    else
        motion_energy = cellfun(@(x)...
            x.torso.mean(1) = [],x.torso.mean(1) = [],...
            x.torso.mean(1) = [],x.torso.mean(1) = [],...
            x.torso.mean(1) = [],x.torso.mean(1) = [],...
            motion_energy);
        
        motion_energy_pre = motion_energy;
    end
            

    ii = ii+1;
end
    
end

function dist = ChiDistance(motion_energy_pre,motion_energy)




end
    





end