clear;
close all;
clc;

[Ipos,Ineg] = GenerateDataset('Dataset_MSRActivity3D',false,'train',1,true);

models_name = 'Drink';
addpath(genpath('exemplarsvm'));
params = esvm_get_default_params;
params.model_type = 'exemplar';
params.dataset_params.display = 1;


stream_params.stream_set_name = 'trainval';
stream_params.stream_max_ex = 10000;
stream_params.must_have_seg = 0;
stream_params.must_have_seg_string = '';
stream_params.model_type = 'exemplar';
stream_params.pos_set = Ipos;
stream_params.cls = models_name;


e_stream_set = esvm_get_pascal_stream(stream_params, ...
                                      params.dataset_params);

% break it up into a set of held out negatives, and the ones used
% for mining
val_neg_set = Ineg((length(Ineg)/2+1):end);
neg_set = Ineg(1:((length(Ineg)/2)));

initial_models = esvm_initialize_exemplars(e_stream_set, params, ...
                                           models_name);
                                       
                                       
                                       
train_params = params;
train_params.detect_max_scale = 0.5;
train_params.detect_exemplar_nms_os_threshold = 1.0;
train_params.detect_max_windows_per_exemplar = 100;
[models] = esvm_train_exemplars(initial_models, ...
                                neg_set, train_params);

val_params = params;
val_params.detect_exemplar_nms_os_threshold = 0.5;
val_params.gt_function = @esvm_load_gt_function;
val_set = cat(1, Ipos(:), val_neg_set(:));
val_set_name = 'valset';
val_grid = esvm_detect_imageset(val_set, models, val_params, val_set_name);


M = esvm_perform_calibration(val_grid, val_set, models, val_params);


%%% colect test data; note that the mode was modified before running this
%%% function
[Ipos_test,Ineg_test] = GenerateDataset('Dataset_MSRActivity3D',true,'test',1,true);

test_params = params;
test_params.detect_exemplar_nms_os_threshold = 0.5;
test_set_name = 'testset';
test_grid = esvm_detect_imageset(Ipos_test, models, test_params, test_set_name);

test_struct = esvm_pool_exemplar_dets(test_grid, models, M, test_params);

maxk = 20;
allbbs = esvm_show_top_dets(test_struct, test_grid, Ipos_test, models, ...
                       params, maxk, test_set_name);


