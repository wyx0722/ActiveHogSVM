#!/bin/bash
echo ==========================================================================;
    ./bin/stipdet -i ~/Videos/Dataset_KTH/video_list_trainval.txt -vpath ~/Videos/Dataset_KTH/ -o KTH_trainval.stip_harris3d.txt -det harris3d -vis no;

    ./bin/stipdet -i ~/Videos/Dataset_KTH/video_list_test.txt -vpath ~/Videos/Dataset_KTH/ -o KTH_test.stip_harris3d.txt -det harris3d -vis no;


echo END
echo ==========================================================================;

