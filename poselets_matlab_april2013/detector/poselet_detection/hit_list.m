classdef hit_list
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% This code is modified by yan.zhang@uni-ulm.de 2016.9.30
%%% Represents a list of hits (poselet/torso/object_bounds hits) in one or
%%% more images
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties
        bounds;      % Nx4 array of single. [min_x min_y width height]
        poselet_id;  % Nx1 arrat of uint16. Unique ID of the detected poselet
        poselet_id_all; % NX1 array of uint16, Unique ID concerning multiple patches and resolutions
        scales;      % the scale for each bounding box
        n_poselets; % 1X1 number, showing number of poselets for all resolution and patches
        score;       % Nx1 array of single. Score of the SVM classifier
        image_id;    % Nx1 array of uint16. Unique ID of the image that contains the hit
        src_idx;     % Nx1 cell of uint32 sets. For each hit, the indices of the source hits. (for example, for a torso, indices of the poselets that voted for it)
        size;        % uint32 size
        color;       % new property, Nx3 array
    end
    methods
        function h = hit_list(bounds,scales,score,poselet_id,poselet_id_all,image_id)
            if nargin==0
                h.size=0;
                h.bounds=zeros(4,0,'single');
                h.poselet_id=zeros(0,1,'uint16');
                h.poselet_id_all=zeros(0,1,'uint16');
                h.scales = zeros(0,1,'single');
                h.score=zeros(0,1,'single');
                h.image_id=zeros(0,1,'uint16');
                h.src_idx = cell(0,0);
                h.n_poselets = 0;
                
            else
                assert(size(bounds,1)==4);
                h.size=size(bounds,2);
                h.bounds=single(bounds);
                h.score(1:h.size,1)=single(score);
                h.poselet_id(1:h.size,1)=uint16(poselet_id);
                h.poselet_id_all(1:h.size,1)=uint16(poselet_id_all);
                h.image_id(1:h.size,1)=uint16(image_id);
                h.scales = scales;
                if exist('src_idx','var')
                   h.src_idx = src_idx;
                else
                   h.src_idx = cell(0,0);
                end
            end
            
        end
        
        function is=isempty(h)
           is=(h.size==0); 
        end

        %%% Appends hits h2 at the end of hits h
        function h=append(h,h2)
            if isempty(h2)
                return;
            end
            rng=1:h2.size;
            h.bounds(:,h.size+rng)      = h2.bounds(:,rng);
            h.score(h.size+rng,:)       = h2.score(rng);
            h.image_id(h.size+rng,:)    = h2.image_id(rng);
            h.poselet_id(h.size+rng,:)  = h2.poselet_id(rng);
            h.scales(h.size+rng,:)  = h2.scales(rng);
            h.poselet_id_all(h.size+rng,:)  = h2.poselet_id_all(rng);
            if ~isempty(h2.src_idx)
                h.src_idx(h.size+rng,:)     = h2.src_idx(rng);
            else
                h.src_idx = {};
            end
            h.size=h.size+h2.size;
        end
                
        function h=reserve(h,len)
            diff = len-length(h.score);
            if diff>0
               h.bounds(1:4,end+(1:diff)) = nan;
               h.score(end+(1:diff),1)=nan;
               h.image_id(end+(1:diff),1)=0;
               h.poselet_id(end+(1:diff),1)=0;
               h.scales(end+(1:diff),1)=0;
               h.poselet_id_all(end+(1:diff),1)=0;
               h.src_idx{len,1}=[];
            end
        end

        %%% Returns a subset of the input hits
        function h=select(h,sel)
            %%% specify the color here
            rng(0);
            h.color = rand(h.size,3);
            if isempty(sel)
                h=hit_list;
                return;
            end
            h.bounds = h.bounds(:,sel);
            h.score = h.score(sel,1);
            h.image_id = h.image_id(sel,1);
            h.poselet_id = h.poselet_id(sel,1);
            h.scales = h.scales(sel,1);
            h.poselet_id_all = h.poselet_id_all(sel,1);
            h.color = h.color(sel,:);
            if ~isempty(h.src_idx)
                h.src_idx = h.src_idx(sel,1);
            end
            h.size=length(h.score);
        end
        

        
        %%% Draws the rotated bounding box of a hit
        function draw_bounds(h,color,linewidth,linestyle,textbg,textfg)
            if ~exist('color','var')
                rng(0);
                
            end
            if ~exist('linewidth','var')
               linewidth=2.5; 
            end
            if ~exist('linestyle','var')
               linestyle='-'; 
            end

            for i=1:h.size
                
                rectangle('position',h.bounds(:,i),'edgecolor',h.color(i,:),'linewidth',linewidth,'linestyle',linestyle);
                if exist('textbg','var')
                    if ~exist('textfg','var')
                       textfg = [1 1 1];           
                    end
                    text(double(h.bounds(1,i)),double(h.bounds(2,i)),num2str(h.score(i),'%4.2f'),'BackgroundColor',textbg,'Color',textfg);
                end
            end            
        end
        
        
        %%% Draws the center of the bounding boxes.The size is according to
        %%% the score
        function hs=draw_points(h,color,linewidth,linestyle,textbg,textfg)
            if ~exist('color','var')
                colors = 1:max(h.poselet_id_all);
                color_c = colors(h.poselet_id_all);
                
            end
            if ~exist('linewidth','var')
               linewidth=0.5; 
            end
            if ~exist('linestyle','var')
               linestyle='-'; 
            end
            
            x = zeros(h.size,1);
            y = x;
            z = ones(h.size,1);
            
            for i=1:h.size
                y(i) = h.bounds(1,i)+h.bounds(3,i)/2;
                x(i) = h.bounds(2,i)+h.bounds(4,i)/2;
                
%                 if exist('textbg','var')
%                     if ~exist('textfg','var')
%                        textfg = [1 1 1];           
%                     end
%                     text(double(h.bounds(1,i)),double(h.bounds(2,i)),num2str(h.score(i),'%4.2f'),'BackgroundColor',textbg,'Color',textfg);
%                 end
            end   
            hs=scatter3(y,x,z,600*h.score+1,color_c,'filled','linewidth',linewidth);
            alpha(hs,0.75);
        end      
        
        
        
    end
end