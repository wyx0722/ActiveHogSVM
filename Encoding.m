function des = Encoding(features,vocabularies)
%%% this function encode the original features into the occurrance histogram according to the learned vocabularies.
%%% features \in N*D, vocabularies \in NC*D
%%% for simplicity, we only try hard voting encoding, following the paper of "dense trajectory...."

vocabularies = (full(vocabularies))';

dist = pdist2(features,vocabularies); % the default distance is euclidean

[val,idx] = min(dist,[],2);
val_t = repmat(val,1,size(dist,2));

des = sum(val_t==dist);
des = des/sum(des);

end
