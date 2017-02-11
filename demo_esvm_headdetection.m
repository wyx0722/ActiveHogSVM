%%% train head detector and perform simple detection
%%% demo

clear;
close all



[Ipos,Ineg] = GenerateDataset('Dataset_MSRActivity3D',false,'train',1,false);

models_name = 'Drink';
addpath(genpath('exemplarsvm_lib'));
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

neg_set = Ineg;

initial_models = esvm_initialize_exemplars(e_stream_set, params, ...
                                           models_name);
   
train_params = params;
train_params.detect_max_scale = 0.5;
train_params.detect_exemplar_nms_os_threshold = 1.0;
train_params.detect_max_windows_per_exemplar = 100;
train_params.train_positives_constant = 10;

[models] = esvm_train_exemplars(initial_models, ...
                                neg_set, train_params);

                            
                            
[Ipos_test,Ineg_test] = GenerateDataset('Dataset_MSRActivity3D',false,'test',1,false);   
test_params = params;
test_params.detect_min_scale = 0.7;
test_params.detect_levels_per_octave = 1;
test_params.detect_exemplar_nms_os_threshold = 0.5;
test_params.detect_max_windows_per_exemplar = 1;
test_set_name = 'testset';

for i = 1:length(Ipos_test)
    test_grid = esvm_detect_imageset(Ipos_test(i), models, test_params, test_set_name);

    test_struct = esvm_pool_exemplar_dets(test_grid, models, [], test_params);

    maxk = 1;
    allbbs = esvm_show_top_dets(test_struct, test_grid, Ipos_test(i), models, ...
                       params, maxk, test_set_name);
end








                            
