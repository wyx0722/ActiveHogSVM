#!/bin/bash


for videos in ~/Videos/Dataset_RochesterADL/*.avi
do
echo processing "$videos"
 ./DenseTrack "$videos" -I 30 > "$videos".txt
done

