function des = Encoding(features,codebook,mu,sigma,option)
%%% this function encode the original features into the occurrance histogram according to the learned codebook.
%%% features \in N*D, codebook \in NC*D
%%% for simplicity, we only try hard voting encoding, following the paper of "dense trajectory...."

codebook = (full(codebook))';
method = option.codebook.encoding_method;

%%% standardization
features = (features-repmat(mu,size(features,1),1))./repmat(sigma,size(features,1),1);
dist = pdist2(features,codebook); % the default distance is euclidean


switch method
case 'hard_voting'
  [val,idx] = min(dist,[],2);
  val_t = repmat(val,1,size(dist,2));

  des = sum(val_t==dist); %%% sum pooling

case 'soft_voting'
 beta = -1;
 val = exp(-beta .* dist);
 des = val./repmat(sum(val,2),1,size(val,2));
 des = sum(des);
otherwise
 disp('error: no other option.');

end


des = des/(sum(des)+1e-6);
if sum(isnan(des))>0
    fdsafasfdsa
end
%%% exclude the largest element, which correspondings to no motion
end
