function des = V2_LocalFeatureEncoding(stip_data,codebook_poselet,...
    codebook_stip,mu_poselet,mu_stip,sigma_poselet,sigma_stip,option)

N = length(stip_data);
stip_data = temporal_reorder(stip_data);
des = {};
for i = 1:N
    
    
    des{i}.video = stip_data{i}.video;
    des{i}.features = feature_encoding_once(codebook_poselet,codebook_stip...
        ,stip_data{i},mu_poselet,sigma_poselet,mu_stip,sigma_stip,option);
end


end




function des = temporal_reorder(src)
NN = length(src);
for ii = 1:NN
    [~,idx] = sort(src{ii}.features(:,7));
    src{ii}.features = src{ii}.features(idx,:);
end
des = src;
clear src;
end





function des = feature_encoding_once(cb_p,cb_s,src,mu_p,sigma_p,mu_s,sigma_s,option)

if option.stip_features.including_scale
    dd = 8;
else
    dd = 10;
end
F = option.poselet.subsampling_factor;
W = option.stip_features.time_window/F;
S = option.stip_features.stride/F;
N = size(src.poselet_occurrence,1);
des = [];
for ii = 1:S:N-W
   
    dd_p = feature_encoding_snippet(src.poselet_occurrence(ii:ii+W),...
        cb_p,mu_p,sigma_p,option);
    ts = src.features(:,7);
    
    interval = find( ts>=(ii-1)*F && ts<=(ii-1+W)*F );
    dd_s = feature_encoding_snippet(src.features(interval,dd:end),...
        cb_s,mu_s,sigma_s,option);
    des = [des;[dd_p dd_s]];
end
    
des = des./repmat(sum(des,2),1,size(des,2));

end



function des = feature_encoding_snippet(src,codebook,mu,sigma,option)

codebook = (full(codebook))';
method = option.codebook.encoding_method;

%%% standardization
src = (src-repmat(mu,size(src,1),1))./repmat(sigma,size(src,1),1);
dist = pdist2(src,codebook); % the default distance is euclidean

switch method
case 'hard_voting'
  [val,idx] = min(dist,[],2);
  val_t = repmat(val,1,size(dist,2));
  des = (val_t==dist); 

case 'soft_voting'
 beta = -1;
 val = exp(-beta .* dist);
 des = val./repmat(sum(val,2),1,size(val,2));

otherwise
 disp('error: no other option.');

end
des = des./sum(des);
end


