function des = Encoding(features,codebook,method)
%%% this function encode the original features into the occurrance histogram according to the learned codebook.
%%% features \in N*D, codebook \in NC*D
%%% for simplicity, we only try hard voting encoding, following the paper of "dense trajectory...."

codebook = (full(codebook))';

dist = pdist2(features,codebook); % the default distance is euclidean
if nargin == 2
    method = 'hard_voting';
end

switch method
case 'hard_voting'
  [val,idx] = min(dist,[],2);
  val_t = repmat(val,1,size(dist,2));

  des = sum(val_t==dist); %%% sum pooling

case 'soft_voting'
 beta = -1;
 val = exp(-beta .* dist);
 val_sum = repmat(sum(val,2),1,size(val,2));
 des = sum(val./val_sum) %%% sum pooling

otherwise
 disp('error: no other option.');

end




des = des/sum(des);


%%% exclude the largest element, which correspondings to no motion
end
