clear;close all;clc



features_head = {};
features_person = {};
features_torso = {};

for ss = 1:5


    features_head = collect_features('Dataset_RochesterADL', 'head', ss);
    features_torso = collect_features('Dataset_RochesterADL', 'torso', ss);
    features_person = collect_features('Dataset_RochesterADL', 'person', ss);
    save(sprintf('denseMBH_rochester_S%i_head.mat',ss),'features_head');
    save(sprintf('denseMBH_rochester_S%i_person.mat',ss),'features_person');
    save(sprintf('denseMBH_rochester_S%i_torso.mat',ss),'features_torso');
    
end

