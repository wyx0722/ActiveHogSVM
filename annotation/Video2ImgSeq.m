function Video2ImgSeq(dataset,resize_factor,subsampling_rate,motion)

switch dataset
    case 'Dataset_MSRActivity3D'
        annot_path = ['/home/yzhang/workspace/ActivityRecognition/annotation/',dataset];
        obj = load([annot_path,'/DataStructure.mat']);
        DataStructure = obj.DataStructure;
        act_list = num2cell(DataStructure.num_activities);
        clear obj;
    case 'Dataset_RochesterADL'
        annot_path = ['/home/yzhang/workspace/ActivityRecognition/annotation/',dataset];
        obj = load([annot_path,'/DataStructure.mat']);
        DataStructure = obj.DataStructure;
        clear obj;
        act_list = importdata([DataStructure.dataset_path,'/activity_list.txt']);
    otherwise
        error('This dataset is not used.');
end


cluster = parcluster('local');
cluster.NumWorkers = 6;
pool = parpool(cluster,6);
parfor ss = 1:DataStructure.num_subjects
    for tt = 1:DataStructure.num_trials
        for aa = 1:DataStructure.num_activities
            filename = sprintf(DataStructure.file_format,act_list{aa},ss,tt);
            disp(filename);
            Video2ImgSeq_one(DataStructure.dataset_path,annot_path,filename,resize_factor,subsampling_rate,motion);
        end
    end
end

delete(gcp('nocreate'));

end



function Video2ImgSeq_one(src_path,des_path,scenario,resize_factor,subsampling_rate,motion)
disp('begin....');
mkdir([des_path,'/',scenario]);
filename = [src_path,'/',scenario];
vv = VideoReader(filename);
i = 1;
ii = 1;

if motion
    opticalFlow = opticalFlowFarneback;
    while hasFrame(vv)
        frame = readFrame(vv);
        ff = imresize(frame,resize_factor);
        ffm = rgb2gray(ff);
        flow = estimateFlow(opticalFlow,ffm);
        if mod(i,subsampling_rate)==0
            imwrite(ff,sprintf([des_path,'/',scenario,'/frame_%i.png'],ii));
            save(sprintf([des_path,'/',scenario,'/frame_%i_flow.mat'],ii),'flow');
            ii = ii+1;
        end
        i = i+1;
    end
    disp('done...');
else
    
    while hasFrame(vv)
        frame = readFrame(vv);
        ff = imresize(frame,resize_factor);
        if mod(i,subsampling_rate)==0
            imwrite(ff,sprintf([des_path,'/',scenario,'/frame_%i.png'],ii));
            ii = ii+1;
        end
        i = i+1;
    end
    disp('done...');
end
end
