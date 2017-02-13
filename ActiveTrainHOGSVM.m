function models = ActiveTrainHOGSVM(dataset,object)

%%% prepare the data for training/validating, the examplar svms for a
%%% specific class label.
%%% this function uses the similar structure with
%%% examplarsvm/esvm_generate_dataset.m
%%% In addition, the annotation scheme should be adjusted for this esvm
%%% lib.

%%% Input: dataset // name of the used dataset
%%% Input: train_or_test // indicator train or test
%%% Input: label_act // only avaliable when train, which label
%%% Input: is_show // only ok when train; (bool) show the positive images in the set
%%% Copyright (C) 2017-1 by Yan Zhang @ ini ulm
%%% All rights reserved.

dataset_path = ['annotation/',dataset];
fprintf('Dataset: %s\n',dataset);
addpath(genpath('exemplarsvm'));

switch dataset
    case 'Dataset_MSRActivity3D'
        n_subs = 5;
        trials = 1;
        n_acts = 16;
        Ipos = {};
        Ineg = {};
        Ipool = {};
        idxp = 1;
        idxn = 1;
        idx = 1;
        maxk = 30;
        max_iter = 5;
        
        
        %%% select a random image and perform annotation
%         rng default;
        aa = randi([1,n_acts],1,1);
        ss = randi([1,n_subs],1,1);
        tt = trials;            
        %%%% retrieve a random images and draw a bounding box
        folders = sprintf('a%02i_s%02i_e%02i_rgb.avi',aa,ss,tt);
        workingDir = [dataset_path,'/',folders];
        imageNames = dir(fullfile(workingDir,'*.png'));
        imageNames = {imageNames.name};
        ii = randi([1,length(imageNames)],1,1);
        fprintf('- collect images %d in video: %s\n',ii,folders); 

        image_file_name = [workingDir,'/',imageNames{ii}];
        I = imread(image_file_name); 
        h = imshow(image_file_name); 
        fprintf('---Draw a box to select %s.\n',object);
        rect = getrect;
        rectangle('Position',rect,'EdgeColor','yellow','LineWidth',2);drawnow;
        
        %%%%put the data within the structure
        recs.folder = workingDir;
        recs.filename = image_file_name;
        recs.source = object;
        [recs.size.width,recs.size.height,recs.size.depth] = size(I);
        recs.segmented = 0;
        recs.imgname = sprintf('%08d',idxp);
        recs.imgsize = size(I);
        recs.database = dataset;

        object1.class = object;
        object1.view = '';
        object1.truncated = 0;
        object1.occluded = 0;
        object1.difficult = 0;
        object1.label = object;
        object1.bbox = [ rect(1),rect(2),rect(1)+rect(3),rect(2)+rect(4)] ;
        object1.bndbox.xmin =object1.bbox(1);
        object1.bndbox.ymin =object1.bbox(2);
        object1.bndbox.xmax =object1.bbox(3);
        object1.bndbox.ymax =object1.bbox(4);
        object1.polygon = [];
        recs.objects = [object1];
        
        Ipos{idxp}.I = I;
        Ipos{idxp}.recs = recs;
        Ipos{idxp}.bbscale = 1;
        
        idxp = idxp +1;
        
        %%% train esvm and negative mining
        %%%% prepare candidate samples
        Ipool = GetAllImages(dataset,n_acts,n_subs,trials);
        used = [];
        %%%% train esvm
        [Imine,~] = GetRandomImages(Ipool,maxk,[]);
        models_name = object;
        params = esvm_get_default_params;
        params.model_type = 'exemplar';
        params.dataset_params.display = 1;

        stream_params.stream_set_name = 'trainval';
        stream_params.stream_max_ex = 10000;
        stream_params.must_have_seg = 0;
        stream_params.must_have_seg_string = '';
        stream_params.model_type = 'exemplar';
        stream_params.pos_set = Ipos;
        stream_params.cls = models_name;

        e_stream_set = esvm_get_pascal_stream(stream_params, ...
                                      params.dataset_params);
        initial_models = esvm_initialize_exemplars(e_stream_set, params, ...
                                           models_name);
        
        train_params = params;
        train_params.detect_max_scale = 0.5;
        train_params.detect_exemplar_nms_os_threshold = 1.0;
        train_params.detect_max_windows_per_exemplar = 100;
        [models] = esvm_train_exemplars(initial_models, ...
                                Imine, train_params);
                            
        kk=1; 
        Cpos = train_params.train_positives_constant;
        Cneg = train_params.train_negatives_constant;
        while (kk <= max_iter) 
            %%% active annotation. 
            %%%% In the neg set, perform detection.
            
            if isempty(Imine)
                fprintf('------ active learning finishes.\n');
                return;
            end
            fprintf('--------- iteration: %i\n',kk);
            dec_params = params;
            dec_params.detect_exemplar_nms_os_threshold = 0.5;
            dec_set_name = 'decset';
            [Ineg,~] = GetRandomImages(Ipool,20,[]);
            for ii = 1:numel(Ineg)
                fprintf('-- %d / %d.\n',ii,numel(Ineg));
                test_grid = esvm_detect_imageset(Ineg(ii), models, dec_params, dec_set_name);
                test_struct = esvm_pool_exemplar_dets(test_grid, models, [], dec_params);
                allbbs = esvm_show_top_dets(test_struct, test_grid, Ineg(ii), models, ...
                           params, 1, dec_set_name);
                if ~isempty(allbbs)
                    is_correct = input(sprintf('is %s detected?(0-no / 1-yes)\n',object));
                else
                    continue ;
                end
                if is_correct
                    Ipos{idxp}.I = Ineg{ii}.I;

    %                 object1.bbox = [allbbs(1),allbbs(2),...
    %                     allbbs(1)+rect(3)*scale,...
    %                     allbbs(2)+rect(4)*scale]; %uniform patch sizes.
    %
    %                 object1.bbox = [allbbs(1),allbbs(2),...
    %                     allbbs(3),...
    %                     allbbs(4)]; %uniform patch sizes.
                    object1.bbox = allbbs;

                    object1.bndbox.xmin =object1.bbox(1);
                    object1.bndbox.ymin =object1.bbox(2);
                    object1.bndbox.xmax =object1.bbox(3);
                    object1.bndbox.ymax =object1.bbox(4);
                    object1.polygon = [];
                    recs.objects = [object1];
                    Ipos{idxp}.recs = recs;

                    idxp = idxp +1;
                else
                    continue;
                end
            end
            %%% we have updated the Ipos, 
            %%% then we (1) collect another neg samples randomly with same number of pos
            %%% (2) extract hog and train linear svm
            clear Ineg Imine;
            [Imine,~] = GetRandomImages(Ipool,maxk,[]);
            train_params=params;
            train_params.patch_size = [rect(3),rect(4)];
            
            %%% becareful about the hyper parameters.
            train_params.train_positives_constant = Cpos/numel(Ipos);
%             train_params.train_negatives_constant = Cneg/numel(Imine);
            
            models = TrainLinearSVM(Ipos,Imine,train_params,models);
            kk = kk+1;
        end
        
                
        
        
    %%%% TODO: develop in the future. At the current stage, we just pick up some 
    %%%% typical faces in the dataset and show the demo results. The active
    %%%% learning story will be definitely investigated in the future.
    %%%% - 2017.2.11
    case 'Dataset_RochesterADL'
        n_subs = 5;
        trials = 1;
        n_acts = 16;
        Ipos = {};
        Ineg = {};
        Ipool = {};
        idxp = 1;
        idxn = 1;
        idx = 1;
        maxk = 30;
        max_iter = 5;
        
        
        %%% select a random image and perform annotation
%         rng default;
        aa = randi([1,n_acts],1,1);
        ss = randi([1,n_subs],1,1);
        tt = trials;            
        %%%% retrieve a random images and draw a bounding box
        folders = sprintf('a%02i_s%02i_e%02i_rgb.avi',aa,ss,tt);
        workingDir = [dataset_path,'/',folders];
        imageNames = dir(fullfile(workingDir,'*.png'));
        imageNames = {imageNames.name};
        ii = randi([1,length(imageNames)],1,1);
        fprintf('- collect images %d in video: %s\n',ii,folders); 

        image_file_name = [workingDir,'/',imageNames{ii}];
        I = imread(image_file_name); 
        h = imshow(image_file_name); 
        fprintf('---Draw a box to select %s.\n',object);
        rect = getrect;
        rectangle('Position',rect,'EdgeColor','yellow','LineWidth',2);drawnow;
        
        %%%%put the data within the structure
        recs.folder = workingDir;
        recs.filename = image_file_name;
        recs.source = object;
        [recs.size.width,recs.size.height,recs.size.depth] = size(I);
        recs.segmented = 0;
        recs.imgname = sprintf('%08d',idxp);
        recs.imgsize = size(I);
        recs.database = dataset;

        object1.class = object;
        object1.view = '';
        object1.truncated = 0;
        object1.occluded = 0;
        object1.difficult = 0;
        object1.label = object;
        object1.bbox = [ rect(1),rect(2),rect(1)+rect(3),rect(2)+rect(4)] ;
        object1.bndbox.xmin =object1.bbox(1);
        object1.bndbox.ymin =object1.bbox(2);
        object1.bndbox.xmax =object1.bbox(3);
        object1.bndbox.ymax =object1.bbox(4);
        object1.polygon = [];
        recs.objects = [object1];
        
        Ipos{idxp}.I = I;
        Ipos{idxp}.recs = recs;
        Ipos{idxp}.bbscale = 1;
        
        idxp = idxp +1;
        
        %%% train esvm and negative mining
        %%%% prepare candidate samples
        Ipool = GetAllImages(dataset,n_acts,n_subs,trials);
        used = [];
        %%%% train esvm
        [Imine,~] = GetRandomImages(Ipool,maxk,[]);
        models_name = object;
        params = esvm_get_default_params;
        params.model_type = 'exemplar';
        params.dataset_params.display = 1;

        stream_params.stream_set_name = 'trainval';
        stream_params.stream_max_ex = 10000;
        stream_params.must_have_seg = 0;
        stream_params.must_have_seg_string = '';
        stream_params.model_type = 'exemplar';
        stream_params.pos_set = Ipos;
        stream_params.cls = models_name;

        e_stream_set = esvm_get_pascal_stream(stream_params, ...
                                      params.dataset_params);
        initial_models = esvm_initialize_exemplars(e_stream_set, params, ...
                                           models_name);
        
        train_params = params;
        train_params.detect_max_scale = 0.5;
        train_params.detect_exemplar_nms_os_threshold = 1.0;
        train_params.detect_max_windows_per_exemplar = 100;
        [models] = esvm_train_exemplars(initial_models, ...
                                Imine, train_params);
                            
        kk=1; 
        Cpos = train_params.train_positives_constant;
        Cneg = train_params.train_negatives_constant;
        while (kk <= max_iter) 
            %%% active annotation. 
            %%%% In the neg set, perform detection.
            
            if isempty(Imine)
                fprintf('------ active learning finishes.\n');
                return;
            end
            fprintf('--------- iteration: %i\n',kk);
            dec_params = params;
            dec_params.detect_exemplar_nms_os_threshold = 0.5;
            dec_set_name = 'decset';
            [Ineg,~] = GetRandomImages(Ipool,20,[]);
            for ii = 1:numel(Ineg)
                fprintf('-- %d / %d.\n',ii,numel(Ineg));
                test_grid = esvm_detect_imageset(Ineg(ii), models, dec_params, dec_set_name);
                test_struct = esvm_pool_exemplar_dets(test_grid, models, [], dec_params);
                allbbs = esvm_show_top_dets(test_struct, test_grid, Ineg(ii), models, ...
                           params, 1, dec_set_name);
                if ~isempty(allbbs)
                    is_correct = input(sprintf('is %s detected?(0-no / 1-yes)\n',object));
                else
                    continue ;
                end
                if is_correct
                    Ipos{idxp}.I = Ineg{ii}.I;

    %                 object1.bbox = [allbbs(1),allbbs(2),...
    %                     allbbs(1)+rect(3)*scale,...
    %                     allbbs(2)+rect(4)*scale]; %uniform patch sizes.
    %
    %                 object1.bbox = [allbbs(1),allbbs(2),...
    %                     allbbs(3),...
    %                     allbbs(4)]; %uniform patch sizes.
                    object1.bbox = allbbs;

                    object1.bndbox.xmin =object1.bbox(1);
                    object1.bndbox.ymin =object1.bbox(2);
                    object1.bndbox.xmax =object1.bbox(3);
                    object1.bndbox.ymax =object1.bbox(4);
                    object1.polygon = [];
                    recs.objects = [object1];
                    Ipos{idxp}.recs = recs;

                    idxp = idxp +1;
                else
                    continue;
                end
            end
            %%% we have updated the Ipos, 
            %%% then we (1) collect another neg samples randomly with same number of pos
            %%% (2) extract hog and train linear svm
            clear Ineg Imine;
            [Imine,~] = GetRandomImages(Ipool,maxk,[]);
            train_params=params;
            train_params.patch_size = [rect(3),rect(4)];
            
            %%% becareful about the hyper parameters.
            train_params.train_positives_constant = Cpos/numel(Ipos);
%             train_params.train_negatives_constant = Cneg/numel(Imine);
            
            models = TrainLinearSVM(Ipos,Imine,train_params,models);
            kk = kk+1;
        end
                            
    otherwise
        error('no other dataset.');
end
end

                        
                    
function [Iset,used] = GetRandomImages(Ipool,maxk,used)
%%% used is the idx list which were used before. We don't draw these.
idx = 1;
if length(used)==length(Ipool)
    fprintf('-- no more images in the pool.\n');
    Iset = {};
    return;
end

while (idx <= maxk)
    ii = randi([1 numel(Ipool)],1,1);
    if sum(used ==ii) == 0  % if not used
        Iset{idx}.I = Ipool{ii}.I;
        idx = idx+1;
        used = [used;ii];
        fprintf('--GetRandomImages, take this\n');
    else
        fprintf('--GetRandomImages, redraw\n');
        continue;
    end
end

end
                    
function Ipool = GetAllImages(dataset,n_acts,n_subs,trials)
idx = 1;
dataset_path = ['annotation/',dataset];
for aa = 1:n_acts
    for ss = 1:n_subs
        for tt = trials:trials
            folders = sprintf('a%02i_s%02i_e%02i_rgb.avi',aa,ss,tt);
            workingDir = [dataset_path,'/',folders];
            imageNames = dir(fullfile(workingDir,'*.png'));
            imageNames = {imageNames.name};
            k = randi([1,length(imageNames)],1,1);
            image_file_name = [workingDir,'/',imageNames{k}];
            I = imread(image_file_name); 
            Ipool{idx}.I = I;
            idx = idx+1;
        end
    end
end

end         
                  

function model = TrainLinearSVM(Ipos,Ineg,params,model)



%%% model initialize
X = [];
% patch_size = round(params.patch_size);

for i = 1:numel(Ipos)
%     bbox = zeros(1,4);
    sbin = params.init_params.sbin;
    bbox = (Ipos{i}.recs.objects.bbox(1:4));
    I = Ipos{i}.I;
    im = double(I(bbox(2):bbox(4),bbox(1):bbox(3),:));
    hog_size = model{1}.model.hg_size;
    patch_size = [hog_size(1)+2,hog_size(2)+2]*sbin;
    im = imresize(im,patch_size);
%     im = act_image_pad(im,sbin);
    x = features_pedro(im,params.init_params.sbin);
    X(:,i) = x(:); %% accumulate the positive samples
end

initial_model{1} = model{1};
initial_model{1}.model.x = X; 
initial_model{1}.model.svxs = []; 
initial_model{1}.model.svbbs = []; 


%%% #positive images = #negative images, however, we need to mine patches.
[model] = esvm_train_exemplars(initial_model, Ineg, params);


end


function des = act_image_pad(img,pad)
%%% zero padding at boundaries
[ny,nx,nz] = size(img);
des = zeros([ny,nx,nz]+2*[pad,pad,0]);
des( (pad+1):(pad+ny),(pad+1):(pad+nx), :) = img;
end
        
