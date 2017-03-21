function feature_des = V2_PoseletFeatureExtraction(feature_src,option)
%%% convert stips in feature_src in feature_des
% option = V2_GetDefaultConfig('KTH');
%% set up path and bound

for i = 1 : length(feature_src);
    vf = [option.fileIO.dataset_path,'/',feature_src{i}.video,'.avi'];
    fprintf('- poselet feature extraction: %s\n',vf);
    poselet_occurrence = PoseletFeatureOneVideo(vf,option);
    
    feature_des{i} = feature_src{i};
    feature_src{i} = {};
    feature_des{i}.poselet_occurrence = poselet_occurrence;
end

   


end



function poselet_occurrence = PoseletFeatureOneVideo(filename,option)

vv = VideoReader(filename);
% poselet_hits_list = {};
img_set = {};
i = 1;
poselet_occurrence = {};

while hasFrame(vv)
    frame = readFrame(vv); 
    img = imgaussfilt(imresize(frame,option.poselet.frame_scaling),0.5);

    %save images to workspace
    if option.poselet.to_imgset
        img_set{i} = img;
    end
    
    [~,poselet_hits_list,~]=detect_objects_in_image(img,option.poselet.model,...
        option.poselet.config);
    %%% create the poselet feature
    if option.poselet.use_detection_score_to_weight_occurrence
        for ii = 1:length(poselet_hits_list.score)
            poselet_occurrence{i}(poselet_hits_list.poselet_id(ii)) = ...
                poselet_occurrence{i}(poselet_hits_list.poselet_id(ii))+...
                poselet_hits_list.score(ii);
        end
    else
        poselet_occurrence{i} = histcounts(poselet_hits_list.poselet_id,1:150);
    end
    poselet_occurrence{i} = poselet_occurrence{i}./sum(poselet_occurrence{i});
    i = i+1;
end
end

    