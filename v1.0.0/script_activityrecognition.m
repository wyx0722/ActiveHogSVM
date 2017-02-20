clear;clc
close all;

models = {};
acc_rates = {};
for i = 1:5
    fprintf('- leave Subject %i ...\n', i);
    [models{i},acc_rates{i}] = ActivityRecognition_train('Dataset_RochesterADL',i);
end

save('ActivityRecognitionRes.m','models','acc_rates');

