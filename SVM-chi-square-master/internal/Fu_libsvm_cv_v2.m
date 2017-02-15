function [c,g,bestcv,acc,cmat,bestmodel] = Fu_libsvm_cv_v2(Ktrain,train_label,opts)
%
% [c,g,bestcv,acc,cmat,bestmodel] = Fu_libsvm_cv_v2(Ktrain,train_label,opts)
%
% This function is to make cross validation and find the best model
%
% Input:
%  Ktrain: Train data. Ytrain:(video_No * feature_dimension)
%  train_label: Train labels. train_video_label(video_No*1)
%  opts.
%    nFold: Number of folds to use. (def 2)
%    useWeight: Use weights to normalise data frequency? (Prevent degenerate solutions for very unbalanced datasets). (def 0)
%    optCrit: 'cvAcc' : libsv cross validation accuracy. (cvAcc)
%    'customKernel', false
%    repeatFinalEst: 1+ For test accuracy estimation, how many times to repeat random folding to average over noise. 
%    cvMethod: 'internal' (libsvm),'explicit' (manual).
%    outProb: boolean. Use prob estimates for final output model?
%
% Return:
%  Optimal params.
% Display:
%  Also displays nfold accuracy after optimization and associated confusion matricies.
%
% Todo: Absolute or mean accuracy optimization/result.
% * Requires libsvm to be added in path.
% Modified and Added from Tim's SVM Code.
%
% change-list:  
%                   add the support to self-defined distance-type for makeKernelPrt (which will use
%                   Fu_compute_kernel_matrices_v2.m version).
%
if(nargin==2)
    opts = struct;
end
opts = getPrmDflt(opts, {'nFold', 2, 'useWeight', false, 'optCrit', 'cvAcc', 'avgBestCv',false, ...
                         'cvSlack', true, 'cvGamma', true, 'customKernel', false, 'repeatFinalEst', 1, ...
                         'specSlack', 0, 'specGamma', 0,'cvMethod','internal','outProb',1},-1 );

if(size(Ktrain,1)~=size(train_label,1))
    error('Ktrain and train_label have mismatching numbers of elements');
end
if(size(Ktrain,1)==0 || size(train_label,1)==0)
    error('Ktrain or train_label missing elements');
end
if(sum(strcmp(opts.optCrit,{'meanErr', 'cvAcc'}))~=1)
    error('Optimization criteria must be "meanErr" or "cvAcc"');
end
    
bestcv = 0;
nClass = numel(unique(train_label));


if(opts.useWeight)
    if(any(train_label==0)) %the class labels are counting from 0.
        h=hist(train_label,0:nClass-1); % histogram positive examples.
        n_total = length(train_label);
    
        w_pos = n_total./(2.*h);
        weightstr = sprintf(' -w%d %0.2f ',[0:nClass-1; w_pos]);
    else    %the class labels are counting from 1.
        h=hist(train_label,1:nClass); % histogram positive examples.
        n_total = length(train_label);
    
        w_pos = n_total./(2.*h);
        weightstr = sprintf(' -w%d %0.2f ',[1:nClass; w_pos]);
    end
else
    weightstr = '';
end



c=1;g=1;

if(opts.cvGamma)
    llog2g = -5:3;
else
    llog2g = 0;
end
if(opts.cvSlack)
    llog2c = 1:7;
else
    llog2c = 0;
end
if(opts.specSlack)
    llog2c = log2(opts.specSlack);
end
if(opts.specGamma)
    llog2g = log2(opts.specGamma);
end

cv_all = zeros(6,6);
aac_all = zeros(6,6);
i=1;
for log2c = llog2c
    j=1;
    for log2g = llog2g
        
        if(opts.customKernel)
            cmd = [weightstr ' -v ', num2str(opts.nFold), ' -c ', num2str(2^log2c)];
            cv_all(i,j) = libsvmtrain(train_label, opts.K, [cmd, ' -t 4 ']);
        else
            if(strcmp(opts.cvMethod,'internal'))
                cmd = [weightstr, ' -q -v ', num2str(opts.nFold), ' -c ', num2str(2^log2c), ' -g ', num2str(2^log2g)];
                cv_all(i,j) = libsvmtrain(train_label, Ktrain, cmd);
            elseif(strcmp(opts.cvMethod,'explicit'))
                opts2 = opts;
                opts2.repeatFinalEst = 2;
                opts2.specSlack = 2^log2c;
                opts2.specGamma = 2^log2g;
                cv_all(i,j) = libsvm_cv_cvacc(Ktrain, train_label, opts2);
            end
        end
        if(strcmp(opts.optCrit,'meanErr'))% || EXTRA)
            cmd = [weightstr, ' -q  -c ', num2str(2^log2c), ' -g ', num2str(2^log2g)];
            model = libsvmtrain(train_label, Ktrain, cmd);
            [lab] = svmpredict(train_label,Ktrain,model);
            cmat = confusion_matrix(2,train_label,lab);
            %for c = 1 : nClass
            %    aac(c) = sum((lab==c)&(train_label==c))/sum(train_label==c);
            %end
            aac_all(i,j) = mean(diag(cmat));
        end
        if(strcmp(opts.optCrit,'meanErr'))
            if(aac_all(i,j)>bestcv)
                bestcv = aac_all(i,j);
                c = 2^log2c;
                g = 2^log2g;
            end
        elseif(strcmp(opts.optCrit,'cvAcc'))
            if(cv_all(i,j)>bestcv)
                bestcv = cv_all(i,j);
                c = 2^log2c;
                g = 2^log2g;
                %fprintf('%g %g %g (best c=%g, g=%g, rate=%g)\n', log2c, log2g, cv, c, g, bestcv);
            end
        else
            error('Unknown optimization criteria');
        end
        j=j+1;
    end
    i=i+1;
end

if(isfield(opts,'avgBestCv') && opts.avgBestCv)
    [i,j]=find(cv_all==max(cv_all(:)));
    ic = round(mean(i));
    ig = round(mean(j));
    [LG,LC] = meshgrid(-5:3,-1:5);
    c = 2^LC(ic,ig);
    g = 2^LG(ic,ig);
end
    

%% To estimate actual performance, do own crossvalidation. Assume 2 fold for now :-/.
acc=0; cmat = zeros(nClass, nClass);
for i = 1 : opts.repeatFinalEst
    l  = randperm(numel(train_label));
    N  = numel(train_label)-ceil(numel(train_label)/opts.nFold);
    X1 = Ktrain(l(1:N),:); X2 = Ktrain(l(N+1:end),:);
    Y1 = train_label(l(1:N));   Y2 = train_label(l(N+1:end));    

    if(opts.customKernel)
        cmd = [weightstr,' -c ' num2str(c)];
        [xtr,xte]=opts.makeKernelPtr(X1, X1,'train',opts.distance_type);
        K1tr = [(1:numel(Y1))', xtr];
        [xtr,xte]=opts.makeKernelPtr(X1, X2,'test',opts.distance_type);
        K1te = [(1:numel(Y2))', xte]; 
        [xtr,xte]=opts.makeKernelPtr(X2, X2,'train',opts.distance_type);
        K2tr = [(1:numel(Y2))', xtr];
        [xtr,xte]=opts.makeKernelPtr(X2, X1,'test',opts.distance_type);
        K2te = [(1:numel(Y1))', xte]; 
        model = libsvmtrain(Y1, K1tr, [cmd, ' -t 4 ']);
        [lab1, acc1p] = svmpredict(Y2, K1te, model); 
        model = libsvmtrain(Y2, K2tr, [cmd, ' -t 4 ']);
        [lab2, acc2p] = svmpredict(Y1, K2te, model); 
    else
        cmd = [weightstr,' -c ' num2str(c) ' -g ' num2str(g)];
        model = libsvmtrain(Y1, X1, cmd);
        [lab1, acc1p] = svmpredict(Y2, X2, model); 
        model = libsvmtrain(Y2, X2, cmd);
        [lab2, acc2p] = svmpredict(Y1, X1, model);
    end
    cmat1 = confusion_matrix(nClass, Y2, lab1);
    acc1  = mean(diag(cmat1));
    cmat2 = confusion_matrix(nClass, Y1, lab2);
    acc2 = mean(diag(cmat2));    
    acc  = acc + 0.5*sum(acc1(1)+acc2(1))/opts.repeatFinalEst;
    %fprintf(1,'2-fold accuracy: %f / %f = %f\n', acc1(1), acc2(1), acc);
    cmat = cmat + 0.5*(cmat1+cmat2)/opts.repeatFinalEst;
end

if(opts.repeatFinalEst>0)
    fprintf(1,'%d-fold accuracy: %f.\n',opts.nFold, acc*100);
end

if(nargout>5)
    if(opts.outProb)
        probstr = ' -b 1 ';
    else
        probstr = ' -b 0 ';
    end
    if(opts.customKernel)
        bestmodel = libsvmtrain(train_label, opts.K, [weightstr,' -c ' num2str(c),  probstr, '-t 4']);
    else
        bestmodel = libsvmtrain(train_label, Ktrain, [weightstr,' -c ' num2str(c) ' -g ' num2str(g) probstr]);
    end
end
