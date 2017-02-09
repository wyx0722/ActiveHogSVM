function [Ipos,Ineg] = GenerateDataset(dataset,using_motion,train_or_test, label_act,is_show)
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
obj = load([dataset_path,'/DataStructure.mat']);
DataStructure = obj.DataStructure;
clear obj;
action_list = importdata([dataset_path,'/action_list.txt']);

switch dataset
    case 'Dataset_MSRActivity3D'

    if strcmp( train_or_test,'test')

        n_subs = 5;
        trials = 2;
        n_acts = 16;

        %%% main loop for every image of every video

        % for ss = 5:5
        %     for tt = 1:DataStructure.num_trials
        Ipos = {};
        Ineg = {};
        idxp = 1;
        idxn = 1;
        for aa = 1:5
            for tt = trials:trials
                for ss = 5:5

                    %%% retrieve the pos images in the current scenario
                    folders = sprintf('a%02i_s%02i_e%02i_rgb.avi',aa,ss,tt);
                    workingDir = [dataset_path,'/',folders];
                    imageNames = dir(fullfile(workingDir,'*.png'));
                    imageNames = {imageNames.name};
                    fprintf('- collect images in video: %s\n',folders); 
                    %%% put the images and annotations to the correct places
                    for i = 1:length(imageNames)
                        image_file_name = [workingDir,'/',imageNames{i}];
                        I = imread(image_file_name); 
                        if ~using_motion
                            Ipos{idxp}.I = I;
                            Ipos{idxp}.label = aa;
                        else
                            %%% if motion is used. Convert a 3-channel
                            %%% image, which are gray-scale image,flowx and
                            %%% flowy respectively.
                         
                            I1 = single(rgb2gray(I));
                            [~,image_file_name,~]=fileparts(image_file_name);
                            obj = load([workingDir,'/',image_file_name,'_flow.mat']);
                            I2 = single(obj.flow.Vx);
                            I3 = single(obj.flow.Vy);
                            Ipos{idxp}.I(:,:,1) = I1;
                            Ipos{idxp}.I(:,:,2) = I2;
                            Ipos{idxp}.I(:,:,3) = I3;
                            Ipos{idxp}.label = aa;
                        end
                            
                        idxp = idxp +1; 
                    end

                end
            end
        end
  
    
    else
        
        n_subs = 1;
        trials = 1;
        n_acts = 5;

        if (label_act > n_acts) || (label_act < 0)
            error('The action label is invalid.');
        end


        %%% main loop for every image of every video

        % for ss = 5:5
        %     for tt = 1:DataStructure.num_trials
        Ipos = {};
        Ineg = {};
        idxp = 1;
        idxn = 1;
        for aa = 1:n_acts
            for tt = trials:trials
                for ss = 1:n_subs

                    if aa == label_act
                        %%% retrieve the pos images in the current scenario
                        folders = sprintf('a%02i_s%02i_e%02i_rgb.avi',aa,ss,tt);
                        workingDir = [dataset_path,'/',folders];
                        imageNames = dir(fullfile(workingDir,'*.png'));
                        imageNames = {imageNames.name};
                        obj = load([workingDir,'/Annotation_yzhang_upperbody.mat']);
                        ant=obj.Annotation;
                        obj = {};
                        fprintf('- collect images in video: %s\n',folders); 
                        %%% put the images and annotations to the correct places
                        %%% if the score is larger than thresh,positive; otherwise
                        %%% negative
                        for i = 1:length(imageNames)
                            if (ant{i}.score > 0.75)
                                image_file_name = [workingDir,'/',imageNames{i}];
                                I = imread(image_file_name); 

                                recs.folder = workingDir;
                                recs.filename = image_file_name;
                                recs.source = label_act;
                                [recs.size.width,recs.size.height,recs.size.depth] = size(I);
                                recs.segmented = 0;
                                recs.imgname = sprintf('%08d',idxp);
                                recs.imgsize = size(I);
                                recs.database = dataset;

                                object.class = 'Drink';
                                object.view = '';
                                object.truncated = 0;
                                object.occluded = 0;
                                object.difficult = 0;
                                object.label = 'Drink';
                                object.bbox = [ ant{i}.rect(1),ant{i}.rect(2),...
                                    ant{i}.rect(1)+ant{i}.rect(3),...
                                    ant{i}.rect(2)+ant{i}.rect(4)]   ;
                                object.bndbox.xmin =object.bbox(1);
                                object.bndbox.ymin =object.bbox(2);
                                object.bndbox.xmax =object.bbox(3);
                                object.bndbox.ymax =object.bbox(4);
                                object.polygon = [];
                                recs.objects = [object];
                                if ~using_motion
                                    Ipos{idxp}.I = I;
                                    Ipos{idxp}.recs = recs;
                                else
                                %%% if motion is used. Convert a 3-channel
                                %%% image, which are gray-scale image,flowx and
                                %%% flowy respectively.

                                    I1 = single(rgb2gray(I));
                                    [~,image_file_name,~]=fileparts(image_file_name);

                                    obj = load([workingDir,'/',image_file_name,'_flow.mat']);
                                    I2 = single(obj.flow.Vx);
                                    I3 = single(obj.flow.Vy);
                                    Ipos{idxp}.I(:,:,1) = I1;
                                    Ipos{idxp}.I(:,:,2) = I2;
                                    Ipos{idxp}.I(:,:,3) = I3;
                                    Ipos{idxp}.recs = recs;
                                end

                                    

                                if is_show
                                    figure(1);imshow(I);
                                    title(sprintf('action=%i, score=%i',label_act,ant{i}.score));
                                    rectangle('Position',ant{i}.rect,'EdgeColor','yellow','LineWidth',2);
                                    drawnow;
                                end


                                idxp = idxp +1; 
                            else
                                image_file_name = [workingDir,'/',imageNames{i}];
                                I = imread(image_file_name); 
                                
                                
                                if ~using_motion
                                    Ineg{idxn}.I = I;
                                else
                                    %%% if motion is used. Convert a 3-channel
                                    %%% image, which are gray-scale image,flowx and
                                    %%% flowy respectively.

                                    I1 = single(rgb2gray(I));
                                    [~,image_file_name,~]=fileparts(image_file_name);
                                    
                                    obj = load([workingDir,'/',image_file_name,'_flow.mat']);
                                    I2 = single(obj.flow.Vx);
                                    I3 = single(obj.flow.Vy);
                                    Ineg{idxn}.I(:,:,1) = I1;
                                    Ineg{idxn}.I(:,:,2) = I2;
                                    Ineg{idxn}.I(:,:,3) = I3;
                                end
                        
                                idxn = idxn + 1;
                            end
                        end
                        clear obj ant
                    else
                        folders = sprintf('a%02i_s%02i_e%02i_rgb.avi',aa,ss,tt);
                        workingDir = [dataset_path,'/',folders];
                        imageNames = dir(fullfile(workingDir,'*.png'));
                        imageNames = {imageNames.name};
                        
                        for i = 1:length(imageNames)
                            image_file_name = [workingDir,'/',imageNames{i}];
                            I = imread(image_file_name); 
                            
                            
                        if ~using_motion
                            Ineg{idxn}.I = I;
                        else
                            %%% if motion is used. Convert a 3-channel
                            %%% image, which are gray-scale image,flowx and
                            %%% flowy respectively.

                            I1 = single(rgb2gray(I));
                            [~,image_file_name,~]=fileparts(image_file_name);

                            obj = load([workingDir,'/',image_file_name,'_flow.mat']);
                            I2 = single(obj.flow.Vx);
                            I3 = single(obj.flow.Vy);
                            Ineg{idxn}.I(:,:,1) = I1;
                            Ineg{idxn}.I(:,:,2) = I2;
                            Ineg{idxn}.I(:,:,3) = I3;
                            
                        end
                        
                            idxn = idxn + 1;
                        end
                    end
                end
            end
        end
    end
        
    case 'Dataset_RochesterADL' 
    bodypart = label_act;
    if strcmp( train_or_test,'test')

        n_subs = 1
        trials = 3;
        n_acts = 5;

        %%% main loop for every image of every video

        % for ss = 5:5
        %     for tt = 1:DataStructure.num_trials
        Ipos = {};
        Ineg = {};
        idxp = 1;
        idxn = 1;
        for aa = 1:10
            for tt = trials:trials
                for ss = 1:1

                    %%% retrieve the pos images in the current scenario
                    folders = sprintf(DataStructure.file_format,action_list{aa},ss,tt);
                    workingDir = [dataset_path,'/',folders];
                    imageNames = dir(fullfile(workingDir,'*.png'));
                    imageNames = {imageNames.name};
                    fprintf('- collect images in video: %s\n',folders); 
                    %%% put the images and annotations to the correct places
                    for i = 1:length(imageNames)
                        image_file_name = [workingDir,'/',imageNames{i}];
                        I = imread(image_file_name); 
                        if ~using_motion
                            Ipos{idxp}.I = I;
                            Ipos{idxp}.label = aa;
                        else
                            %%% if motion is used. Convert a 3-channel
                            %%% image, which are gray-scale image,flowx and
                            %%% flowy respectively.
                         
                            I1 = single(rgb2gray(I));
                            [~,image_file_name,~]=fileparts(image_file_name);
                            obj = load([workingDir,'/',image_file_name,'_flow.mat']);
                            I2 = single(obj.flow.Vx);
                            I3 = single(obj.flow.Vy);
                            Ipos{idxp}.I(:,:,1) = I1;
                            Ipos{idxp}.I(:,:,2) = I2;
                            Ipos{idxp}.I(:,:,3) = I3;
                            Ipos{idxp}.label = aa;
                        end
                            
                        idxp = idxp +1; 
                    end

                end
            end
        end
  
    
    else
        
        n_subs = 1;
        trials = 1;
        n_acts = 5;


        %%% main loop for every image of every video

        % for ss = 5:5
        %     for tt = 1:DataStructure.num_trials
        Ipos = {};
        Ineg = {};
        idxp = 1;
        idxn = 1;
        for aa = 1:2
            for tt = trials:trials
                for ss = 1:1


                        %%% retrieve the pos images in the current scenario
                        folders = sprintf(DataStructure.file_format,action_list{aa},ss,tt);
                        workingDir = [dataset_path,'/',folders];
                        imageNames = dir(fullfile(workingDir,'*.png'));
                        imageNames = {imageNames.name};
                        obj = load([workingDir,'/Annotation_torso.mat']);
                        ant=obj.Annotation;
                        obj = {};
                        fprintf('- collect images in video: %s\n',folders); 
                        %%% put the images and annotations to the correct places
                        %%% if the score is larger than thresh,positive; otherwise
                        %%% negative
                        for i = 1:1:length(imageNames)
                            if ~isempty(ant{i})
                                image_file_name = [workingDir,'/',imageNames{i}];
                                I = imread(image_file_name); 

                                recs.folder = workingDir;
                                recs.filename = image_file_name;
                                recs.source = label_act;
                                [recs.size.width,recs.size.height,recs.size.depth] = size(I);
                                recs.segmented = 0;
                                recs.imgname = sprintf('%08d',idxp);
                                recs.imgsize = size(I);
                                recs.database = dataset;
                                
                                object.class = 'Drink';
                                object.view = '';
                                object.truncated = 0;
                                object.occluded = 0;
                                object.difficult = 0;
                                object.label = 'Drink';
                                object.bbox = [ ant{i}.rect(1),ant{i}.rect(2),...
                                    ant{i}.rect(1)+ant{i}.rect(3),...
                                    ant{i}.rect(2)+ant{i}.rect(4)]   ;
                                object.bndbox.xmin =object.bbox(1);
                                object.bndbox.ymin =object.bbox(2);
                                object.bndbox.xmax =object.bbox(3);
                                object.bndbox.ymax =object.bbox(4);
                                object.attributes = ant{i}.bodypart;
                                object.polygon = [];
                                recs.objects = [object];
                                if ~using_motion
                                    Ipos{idxp}.I = I;
                                    Ipos{idxp}.recs = recs;
                                else
                                %%% if motion is used. Convert a 3-channel
                                %%% image, which are gray-scale image,flowx and
                                %%% flowy respectively.

                                    I1 = single(rgb2gray(I));
                                    [~,image_file_name,~]=fileparts(image_file_name);

                                    obj = load([workingDir,'/',image_file_name,'_flow.mat']);
                                    I2 = single(obj.flow.Vx);
                                    I3 = single(obj.flow.Vy);
                                    Ipos{idxp}.I(:,:,1) = I1;
                                    Ipos{idxp}.I(:,:,2) = I2;
                                    Ipos{idxp}.I(:,:,3) = I3;
                                    Ipos{idxp}.recs = recs;
                                end

                                    

                                if is_show
                                    figure(1);imshow(I);
                                    rectangle('Position',ant{i}.rect,'EdgeColor','yellow','LineWidth',2);
                                    drawnow;
                                end


                                idxp = idxp +1; 
                            else
                                image_file_name = [workingDir,'/',imageNames{i}];
                                I = imread(image_file_name); 
                                
                                
                                if ~using_motion
                                    Ineg{idxn}.I = I;
                                else
                                    %%% if motion is used. Convert a 3-channel
                                    %%% image, which are gray-scale image,flowx and
                                    %%% flowy respectively.

                                    I1 = single(rgb2gray(I));
                                    [~,image_file_name,~]=fileparts(image_file_name);
                                    
                                    obj = load([workingDir,'/',image_file_name,'_flow.mat']);
                                    I2 = single(obj.flow.Vx);
                                    I3 = single(obj.flow.Vy);
                                    Ineg{idxn}.I(:,:,1) = I1;
                                    Ineg{idxn}.I(:,:,2) = I2;
                                    Ineg{idxn}.I(:,:,3) = I3;
                                end
                        
                                idxn = idxn + 1;
                            end
                        end
                        clear obj ant
                end
            end
        end
    end
    otherwise
        error ('choose [train] or [test]\n');
end
        

fprintf('Data Collection: %s,  #img_pos=%i,  #img_neg=%i\n',label_act,idxp-1,idxn-1);

                    
end
