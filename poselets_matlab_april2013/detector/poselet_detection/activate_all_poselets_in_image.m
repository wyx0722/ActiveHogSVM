function poselet_hits=activate_all_poselets_in_image(img, model,config, option)

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
phog=image2phog(img, config, option);

%fprintf('Done in %4.2f secs.\n',etime(clock,total_start_time));

%fprintf('Detecting poselets... ');
%start_time=clock;

%% poselet detection and q-score
poselet_hits = detect_poselets_MaxPooling(phog,model.svms,config, option);  % here we retain all the poselet hits.
poselet_hits.score = -poselet_hits.score.*model.logit_coef(poselet_hits.poselet_id,1)-model.logit_coef(poselet_hits.poselet_id,2);
poselet_hits.score = 1./(1+exp(-poselet_hits.score));

% Reorder the poselet hits, by the index of the pre-defined poselet-set
% [srt,srtd]=sort(poselet_hits.poselet_id_all,'ascend');
% poselet_hits = poselet_hits.select(srtd); 
%fprintf('Done in %4.2f secs.\n',etime(clock,start_time));



