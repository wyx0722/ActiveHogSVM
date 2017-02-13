function head_models = train_head_rochesterADL()
%%% leave-one-person-out cross validation on head esvm training.
addpath(genpath('exemplarsvm_lib'));
addpath(genpath('annotation'));

sub_list = 1:5;
head_models = cell(numel(sub_list),1);
for i = 1:5
    sub_list((sub_list==i))=[]; %%% leave that subject out
    [Ipos,Ineg] = GenerateDataset('Dataset_RochesterADL',false,'train', 'head',false);
    head_models{i} = train_esvm(Ipos,Ineg,i);
    clear Ipos Ineg
    %head_models{i}.excluded_subject = i;
end

save('esvm_head_rochesteradl.m',head_models);

end



function models = train_esvm(Ipos,Ineg,ii)

models_name = 'head';
params = esvm_get_default_params;
params.model_type = 'exemplar';
params.dataset_params.display = 0;

stream_params.stream_set_name = 'trainval';
stream_params.stream_max_ex = 10000;
stream_params.must_have_seg = 0;
stream_params.must_have_seg_string = '';
stream_params.model_type = 'exemplar';
stream_params.pos_set = Ipos;
stream_params.cls = models_name;


e_stream_set = esvm_get_pascal_stream(stream_params, ...
                                      params.dataset_params);

neg_set = Ineg;

initial_models = esvm_initialize_exemplars(e_stream_set, params, ...
                                           models_name);
   
train_params = params;
train_params.detect_max_scale = 0.5;
train_params.detect_exemplar_nms_os_threshold = 1.0;
train_params.detect_max_windows_per_exemplar = 100;
train_params.train_positives_constant = 10;
train_params.dataset_params.localdir=sprintf('/home/zhang/workspace/ActiveHogSVM/esvm_head_%i',ii);
[models] = esvm_train_exemplars(initial_models, ...
                                neg_set, train_params);
                            
close all;
end
