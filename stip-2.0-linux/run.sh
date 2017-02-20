#!/bin/bash
echo ==========================================================================;
echo Extract Leave-one-subject-out features: "$1";
    ./bin/stipdet -i ~/Videos/Dataset_RochesterDailyActivity/stip_category/video_list_s"$1".txt -vpath ~/Videos/Dataset_RochesterDailyActivity/ -o RochesterADL_subject"$1".stip_harris3d.txt -det harris3d -nplev 2 -plev0 1 -vis no;

    ./bin/stipdet -i ~/Videos/Dataset_RochesterDailyActivity/stip_category/video_list_excludings"$1".txt -vpath ~/Videos/Dataset_RochesterDailyActivity/ -o RochesterADL_leave_subject"$1"_out.stip_harris3d.txt -det harris3d -nplev 2 -plev0 1 -vis no;


echo END
echo ==========================================================================;

