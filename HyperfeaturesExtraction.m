function deepmodel = HyperfeaturesExtraction(stip_data_S,...
                                                 stip_data_T,...
                                                 option)

%%% extract hyper features from harris3d low-level features.
%%% feature learning is performed using kmeans
%%% architecture: ...-> kmeans -> encoding -> pooling ->...


% %%% first we reorder all the stips and features, so that they follow the
% %%% correct temporal order
% stip_data_S = temporal_reorder(stip_data_S);
% stip_data_T = temporal_reorder(stip_data_T);
deepmodel = {};
W = option.hyperfeatures.encoding_W;
S = option.hyperfeatures.encoding_S;

%%% deep architecture is as follows
for ll = 1:option.hyperfeatures.num_layers
    fprintf('================ layer %i================\n',ll);
    
    %%% generate the codebook; standardization is included 
    fprintf('- learning codebook...\n');
    [codebook,SUMD,opts,running_info,mu,sigma]=...
        CreateCodebook(stip_data_S,option);
    deepmodel{ll}.CodebookLearning.codebook = codebook;
    deepmodel{ll}.CodebookLearning.SUMD = SUMD;
    deepmodel{ll}.CodebookLearning.opts = opts;
    deepmodel{ll}.CodebookLearning.running_info = running_info;
    deepmodel{ll}.RawFeatureStandardization.mu = mu;
    deepmodel{ll}.RawFeatureStandardization.sigma = sigma;

    if sum(sum(isnan(codebook)))~=0
        fdafa
    end
   
    if ll < option.hyperfeatures.num_layers
        %%% feature encoding
        fprintf('- feature encoding...\n');
        stip_data_S  = feature_encoding(codebook,stip_data_S,mu,sigma,option);
        stip_data_T  = feature_encoding(codebook,stip_data_T,mu,sigma,option);
        %%% pooling (we do sum pooling here)
        fprintf('- feature pooling...\n');
        stip_data_S = feature_pooling(stip_data_S,W,S,option);
        stip_data_T = feature_pooling(stip_data_T,W,S,option);
        W = option.hyperfeatures.rfscaling*W; % update receptive field size
        
    else
        [deepmodel{ll}.svm.model,deepmodel{ll}.svm.Yt,...
            deepmodel{ll}.svm.Yp,deepmodel{ll}.svm.meta_res] =...
            ActivityRecognition(codebook,stip_data_S,stip_data_T,...
            mu,sigma,option);
    end
    
    
end
    
   

end




function stip_des = feature_pooling(stip_src,W,S,option)

NN = length(stip_src);
if option.stip_features.including_scale
    dd = 8;
else
    dd = 10;
end

stip_des = {};
for ii = 1:NN
    stip_des{ii}.video = stip_src{ii}.video;
    time_stamp = stip_src{ii}.features(:,7);
    
    idxx = 1;
    interval =min(time_stamp):S:max(time_stamp)-W;
    
    if isempty(interval)
        stip_des{ii}.features = stip_src{ii}.features;
        continue;
    end
    
    
    
    for tt = interval
        
        idxt = find(time_stamp >= tt & time_stamp<=tt+W);

        if isempty(idxt)
            stip_des{ii}.features(idxx,:)=stip_des{ii}.features(idxx-1,:);
            stip_des{ii}.features(idxx,dd:end) = 0;
            idxx = idxx+1;
            continue;
        end
        
        
        tmp = sum(stip_src{ii}.features(idxt,dd:end),1); % sum pooling
       
        stip_des{ii}.features(idxx,1:dd-1) = ...
            stip_src{ii}.features(idxt(1),1:dd-1);    
        stip_des{ii}.features(idxx,dd:dd+size(tmp,2)-1) = tmp./sum(tmp); %l1-normalize
        
        idxx = idxx+1;
    end
    if ~isfield(stip_des{ii},'features')
        fdafdsaf
    end;
end




end





function des = temporal_reorder(src)
NN = length(src);
for ii = 1:NN
    [~,idx] = sort(src{ii}.features(:,7));
    src{ii}.features = src{ii}.features(idx,:);
end
des = src;
end

    



function stip_data_des = feature_encoding(codebook,stip_data_src,mu,sigma,option)

if option.stip_features.including_scale
    dd = 8;
else
    dd = 10;
end

NN = length(stip_data_src);
stip_data_des = cell(NN,1);

for ii = 1:NN
    
    
    stip_data_des{ii}.video = stip_data_src{ii}.video;
    
    
    stip_data_des{ii}.features(:,1:dd-1) = stip_data_src{ii}.features(:,1:dd-1);
    tmp=feature_encoding_onevideo(stip_data_src{ii}.features(:,dd:end),...
        codebook,mu,sigma,option);
    stip_data_des{ii}.features(:,dd:dd+size(tmp,2)-1) = tmp;

    
end


end




function des = feature_encoding_onevideo(src,codebook,mu,sigma,option)


codebook = (full(codebook))';
method = option.codebook.encoding_method;






%%% standardization
src = (src-repmat(mu,size(src,1),1))./repmat(sigma,size(src,1),1);

dist = pdist2(src,codebook); % the default distance is euclidean


switch method
case 'hard_voting'
  [val,idx] = min(dist,[],2);
  val_t = repmat(val,1,size(dist,2));

  des = val_t==dist; 

case 'soft_voting'
 beta = -1;
 val = exp(-beta .* dist);
 val_sum = repmat(sum(val,2),1,size(val,2));

otherwise
 disp('error: no other option.');

end

end








