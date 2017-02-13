function BoundingBoxAnnotation(dataset,bodypart)

if nargin == 1
    bodypart = 'head';
end

participant = input('input your name:\n','s');
obj = load([dataset,'/DataStructure.mat']);
DataStructure = obj.DataStructure;
clear obj;
action_list = importdata([dataset,'/action_list.txt']);
%%% main loop for every image of every video
% for ss = 1:DataStructure.num_subjects/2
% % for ss = 5:5
% %     for tt = 1:DataStructure.num_trials
%      for tt = 1:1
%         for aa = 1:DataStructure.num_activities

switch dataset

    case 'Dataset_RochesterADL'

        for ss = 1:DataStructure.num_subjects
            idx = 1;
            Annotationt = {};
            img_set = {}; %%% store all collected image patches

            for tt = 1:1
                for aa = 1:DataStructure.num_activities
%                 for aa = 1:1

                    workingDir = [dataset,'/',sprintf(DataStructure.file_format,action_list{aa},ss,tt)];
                        
                    imageNames = dir(fullfile(workingDir,'*.png'));
                    imageNames = {imageNames.name};
                    fprintf('annotate the %s\n',bodypart);
                    fprintf('You will see %i images.',length(imageNames));
                    fprintf('From each of them, please draw a bounding box to define the most relevant region.\n');

                    Annotation1 = cell(length(imageNames),1);
                    img_set1 = cell(length(imageNames),1);
                    
                    %%% annotation every dd image
                    dd = 5;
                    for i = 1:dd:numel(imageNames)
                        image_file_name = [workingDir,'/',imageNames{i}];
                        I = imread(image_file_name);
                        h = figure(1);
                        imshow(I);
                        jump = input('Did you annotate similar images? (yes-1,no-0):');
                        if jump
                            Annotation1{i}=[];
                            img_set1{i}=[];
                            continue;
                        end
                            
                        fprintf('---Draw a box to select %s.\n',bodypart);
                        Annotation1{i}.rect = getrect;
                        rectangle('Position',Annotation1{i}.rect,'EdgeColor','yellow','LineWidth',2);drawnow;
                        Annotation1{i}.bodypart.name = bodypart;
                        Annotation1{i}.bodypart.yaw = input('--- Input the yaw (front,side,back):','s');
                        Annotation1{i}.bodypart.pitch = input('--- Input the pitch (up,forward,down):','s');
                        Annotation1{i}.subject = ss;
                        Annotation1{i}.annotator = participant;
                        ttt = input ('Is the head occluded by objects?(yes-1,no-0):');
                        Annotation1{i}.occluded_by_objects = ttt;
                        
                        Annotation1{i}.filename=image_file_name;
                        img_set1{i} = imcrop(I,Annotation1{i}.rect);
                        show_image_set(img_set1);
                        idx = idx+1;
                        close(h);
                        
                    end
                    Annotationt = [Annotationt;Annotation1];
                    img_set = [img_set;img_set1];
                    
                    %%% save the annotation to the corresponding folder

                end
            end
                    %%% discard redundant training data
            DDD = find(~cellfun(@isempty,Annotationt));
            Annotation = Annotationt;
            for ii = 1:length(DDD)
                show_image_set(img_set,DDD(ii));
                xx = input ('this is redundant?(yes-1,no-0):\n');
                if xx
                    Annotation{DDD(ii)}=[];
                end
                
            end

            save([dataset,'/Annotation_',participant,'_',bodypart,'_subject_',num2str(ss),'.mat'],'Annotation');
        end
        


        
    case 'Dataset_MSRActivity3D'

        for ss = 1:DataStructure.num_subjects
            for tt = 1:DataStructure.num_trials
                for aa = 1:DataStructure.num_activities
                    workingDir = [dataset,'/',sprintf(DataStructure.file_format,action_list{aa},ss,tt)];

                    imageNames = dir(fullfile(workingDir,'*.png'));
                    imageNames = {imageNames.name};
                    
                    fprintf('Which region is most relevant with %s??\n',action_list{aa});
                    fprintf('You will see %i images.',length(imageNames));
                    fprintf('From each of them, please draw a bounding box to define the most relevant region.\n');
                    fprintf('In addition, please score the relevance from 0 to 1.\n');
                    Annotation = {};

                    %%% annotation
                    for i = 1:numel(imageNames)
                        image_file_name = [workingDir,'/',imageNames{i}];
                        h = imshow(image_file_name); 
                        fprintf('---Draw a box to select the most related region with %s.\n',action_list{aa});
                        Annotation{i}.rect = getrect;
                        rectangle('Position',Annotation{i}.rect,'EdgeColor','yellow','LineWidth',2);drawnow;
                        Annotation{i}.score = input('specify the score from 0 to 1:\n ');
                        if isempty(Annotation{i}.score)
                            Annotation{i}.score = input('specify the score from 0 to 1:\n ');
                        end
                        if Annotation{i}.score < 0 || Annotation{i}.score > 1
                            fprintf('ERROR: score should be between 0 and 1.');
                            Annotation{i}.score = input('Please enter a new value:\n');
                        end
                        Annotation{i}.image_name = imageNames{i};
                        Annotation{i}.participant = participant;
                        close all;
                    end
                    %%% save the annotation to the corresponding folder
                    save([workingDir,'/Annotation_',participant,'.mat'],'Annotation');
                end
            end
        end

            
end

end



function show_image_set(img_set,xx)
ddd = find(~cellfun(@isempty,img_set));
N = length(ddd); %% #nonempty elements
nx = ceil(sqrt(N));
figure(4);
if nargin == 1    
    for ii = 1:N
        subplot(nx,nx,ii);
        imshow(img_set{ddd(ii)});
    end
        
else
    for ii = 1:N
        subplot(nx,nx,ii);
        imshow(img_set{ddd(ii)}*0.3);
    end
    subplot(nx,nx,find(ddd==xx));
    imshow(img_set{xx});

end

end
        
        











