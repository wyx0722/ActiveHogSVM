clear;clc;
close all;

bodypart = {'head','torso','person'};

%%% only run script for RochesterADL
for ss = 1:5
  for bb = 1:length(bodypart)
      fprintf('-create vocabularies for subject %i %s\n',ss,bodypart{bb});
      vocabularies = CreateVocabulary('Dataset_RochesterADL',bodypart{bb},ss);
      save(sprintf('vocabularies_Rochester_S%i_%s.mat',ss,bodypart{bb}),'vocabularies');
      clear vocabularies
   end
end

