function [K_train, K_test] = Fu_compute_kernel_matrices(M_train, M_test, mode)
% function to compute Chi-squared kernel matrices weighted by mean distance (A)
% use slmetric_pw to compute paire-wise metrics, by Dahua Lin (matlab central file exchange)

% only want to calculate one of them: empty the other matrix.


if(nargin>=2)
   mode = 'both'; 
elseif ~isempty(M_train)
    mode = 'train';
elseif ~isempty(M_test)
    mode ='test';
end

% note: A is mean distance (chi-squared) between all samples, generally multiply by a factor works better
A = compute_A_testimp(M_train)*2;

if strcmp(mode, 'both')||strcmp(mode, 'train')
    num_samp_train = size(M_train, 1);
    K_train = exp(-slmetric_pw(M_train', M_train', 'chisq')/A);
%    K_train = [(1:num_samp_train)', K_train]; % metadata for libsvm
else
    K_train = [];
end

if strcmp(mode, 'both')||strcmp(mode, 'test')
    num_samp_test = size(M_test, 1);
    K_test = exp(-slmetric_pw(M_test', M_train', 'chisq')/A);    

   % K_test = [(1:num_samp_test)', K_test];   % metadata for libsvm
else
    K_test = [];
end

end
