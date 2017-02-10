function poselet_hits=activate_all_poselets_in_imagesequence(img1,img2, model,config)

% -img1 - previous frame
% -img2 - current frame
% -static poselet detection is performed on img2, the current frame
% -dense optical flow is computed over img1 to img2
% -for each poselet activation,we consider the optical flow within the
% bounding box. The poselet score is then modified by the optical flow
% energy. The final activation vector is then normalized. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% The code is modified by yan.zhang@uni-ulm.de at 2016.09.09, based on:
%%%----------------------------------------------------------------
%%% Given an RGB uint8 image returns the locations and scores of all objects
%%% in the image (bounds_predictions), of all poselet hits (poselet_hits)
%%% and, optionally for mammals, of all torso locations (torso_predictions)
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if config.DEBUG>0
    config.DEBUG_IMG = img;
end


%% hog extraction
%fprintf('Computing pyramid HOG (hint: You can cache this)... ');
%total_start_time=clock;
phog=image2phog(img2, config);

%fprintf('Done in %4.2f secs.\n',etime(clock,total_start_time));

%fprintf('Detecting poselets... ');
%start_time=clock;

%% poselet detection and q-score
poselet_hits = detect_poselets_MaxPooling(phog,model.svms,config);  % here we retain all the poselet hits.
poselet_hits.score = -poselet_hits.score.*model.logit_coef(poselet_hits.poselet_id,1)-model.logit_coef(poselet_hits.poselet_id,2);
poselet_hits.score = 1./(1+exp(-poselet_hits.score));

% Reorder the poselet hits, by the index of the pre-defined poselet-set
[srt,srtd]=sort(poselet_hits.poselet_id_all,'ascend');
poselet_hits = poselet_hits.select(srtd); 
%fprintf('Done in %4.2f secs.\n',etime(clock,start_time));

%% optical flow from img1 to img2
%%% notice that this optical flow reweighting is only feasible for dense
%%% poselet activation vector
n_hits = length(poselet_hits.poselet_id);

if ~isempty(n_hits)
    uvo = estimate_flow_interface(img1, img2, 'hs-brightness-nomedian');
    flow_energy = sqrt(uvo(:,:,1).^2+uvo(:,:,2).^2);

    %%% rescore the poselet activations by motion flow in the bounding box
    %%% after reweighting, the new score vector is then normalized based on L2
    %%% term
    motion_score = zeros(n_hits,1);
    bb = poselet_hits.bounds;
    for i = 1:n_hits
        r = bb(i,1);
        c = bb(i,2);
        w = bb(i,3);
        h = bb(i,4);
        roi = flow_energy([r:r+w,c:c+h]);
        motion_score(i) = sum(sum(roi));
    end
end

poselet_hits.score = poselet_hits.score.*motion_score;
poselet_hits.score = poselet_hits.score/norm(poseelt_hits.score,2);




















