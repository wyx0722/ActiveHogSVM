function refine_body_part(video)

workingDir=...
    ['/home/yzhang/workspace/ActivityRecognition/annotation/Dataset_RochesterADL/',...
    video];


imageNames = dir(fullfile(workingDir,'*.png'));
imageNames = {imageNames.name};
N = length(imageNames);
obj = load([workingDir,'/rect.mat']);
rect = obj.rect;
clear obj;
for i = 1:N
    image_file_name = [workingDir,'/',imageNames{i}];
    img = imread(image_file_name);
    rect{i}.person=reshape(rect{i}.person,[1,4]);
    rect{i}.head=reshape(rect{i}.head,[1,4]);
    rect{i}.torso=reshape(rect{i}.torso,[1,4]);
    
    figure(1);hh=imshow(img);hold on;
    rectangle('Position',rect{i}.head,'EdgeColor','red','LineWidth',2);
    rectangle('Position',rect{i}.person,'EdgeColor','yellow','LineWidth',2);
    rectangle('Position',rect{i}.torso,'EdgeColor','blue','LineWidth',2);
    drawnow;
    %%% manual stops according to detection scores
    if bboxOverlapRatio(rect{i}.person, rect{i}.head)<0.03 || bboxOverlapRatio(rect{i}.torso, rect{i}.head)>0.1
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
    clf;
end
save([workingDir,'/rect.mat'],'rect');


end