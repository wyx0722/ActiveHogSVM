MSRActivity3D
- The frames are extracted by every 10 frames.
- annotation has a bounding box for the most relevant region with the action
- annotated data: subject 1-5, actions 1-16, trials 1
- annotation participants: 2


RochesterADL
- The frames are extracted by every 30 frames.
- 



Annotation pipeline Rochester ADL:
- we annotate the head ,torso and the person bounding boxes in each frame.
- The frames are extracted every 30 frames from the video. See above
- we use the pre-trained poselet detector to find person and torso
- we use exemplar-svm to detect head. The images for training were collected by ourselves.
- The bounding boxes are saved in the file rect.m, in the corresponding folder of the image sequences.
- script usage: 
-- (1) BoundingBoxAnnotation.m  // find head images for esvm training
-- (2) train_head_rochesterADL.m // train leave-one-out esvms for head detection
-- (3) automatic_draw_boundingbox.m // first automatic detection and then manual refining the annotation.
-- (4) ** other files in src_body_part_annotation are assistive functions.
-- (5) ** currently, we re-arranged the files. So that some paths should be updated in future.


ESVM training until 2017.2.13
- we collect head images using the script BoundingBoxAnnotation.m
- For each person, we basically selected head according to his/her view: front,front down, side, side down, back
- In addition, we consider the case whether the head is occluded heavily by objects.
- We save the annotation file to Annotation_yzhang_head_subject_*.mat
- We trained 5 groups of esvms respectively, each of which leaves one subject out. 
