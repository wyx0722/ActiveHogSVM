#!/bin/bash
echo ==========================================================================;
echo Extract Leave-one-subject-out features: "$1";
    ./bin/stipdet -i ~/Videos/Dataset_Weizmann/stip_category/video_list.subject_"$1".txt -vpath ~/Videos/Dataset_Weizmann/ -o Weizmann_subject_"$1".stip_harris3d.txt -det harris3d -nplev 2 -plev0 0 -vis no;

    ./bin/stipdet -i ~/Videos/Dataset_Weizmann/stip_category/video_list.leave_subject_"$1"_out.txt -vpath ~/Videos/Dataset_Weizmann/ -o Weizmann_leave_subject_"$1"_out.stip_harris3d.txt -det harris3d -nplev 2 -plev0 0 -vis no;


echo END
echo ==========================================================================;

