% Starter code prepared by James Hays for CS 143, Brown University
% This function returns detections on all of the images in a given path.
% You will want to use non-maximum suppression on your detections or your
% performance will be poor (the evaluation counts a duplicate detection as
% wrong). The non-maximum suppression is done on a per-image basis. The
% starter code includes a call to a provided non-max suppression function.
function [bboxes, confidences, image_ids] = ....
    run_detector(test_scn_path, w, b, feature_params, scale_step, cell_step, confident_thresh)
% 'test_scn_path' is a string. This directory contains images which may or
%    may not have faces in them. This function should work for the MIT+CMU
%    test set but also for any other images (e.g. class photos)
% 'w' and 'b' are the linear classifier parameters
% 'feature_params' is a struct, with fields
%   feature_params.template_size (probably 36), the number of pixels
%      spanned by each train / test template and
%   feature_params.hog_cell_size (default 6), the number of pixels in each
%      HoG cell. template size should be evenly divisible by hog_cell_size.
%      Smaller HoG cell sizes tend to work better, but they make things
%      slower because the feature dimensionality increases and more
%      importantly the step size of the classifier decreases at test time.

% 'bboxes' is Nx4. N is the number of detections. bboxes(i,:) is
%   [x_min, y_min, x_max, y_max] for detection i.
%   Remember 'y' is dimension 1 in Matlab!
% 'confidences' is Nx1. confidences(i) is the real valued confidence of
%   detection i.
% 'image_ids' is an Nx1 cell array. image_ids{i} is the image file name
%   for detection i. (not the full path, just 'albert.jpg')

% The placeholder version of this code will return random bounding boxes in
% each test image. It will even do non-maximum suppression on the random
% bounding boxes to give you an example of how to call the function.

% Your actual code should convert each test image to HoG feature space with
% a _single_ call to vl_hog for each scale. Then step over the HoG cells,
% taking groups of cells that are the same size as your learned template,
% and classifying them. If the classification is above some confidence,
% keep the detection and then pass all the detections for an image to
% non-maximum suppression. For your initial debugging, you can operate only
% at a single scale and you can skip calling non-maximum suppression.

test_scenes = dir( fullfile( test_scn_path, '*.jpg' ));

%initialize these as empty and incrementally expand them.
bboxes = zeros(0,4);
confidences = zeros(0,1);
image_ids = cell(0,1);
t_c = feature_params.template_size / feature_params.hog_cell_size;

for i = 1:length(test_scenes)
    
    fprintf('Detecting faces in %s\n', test_scenes(i).name)
    img = imread( fullfile( test_scn_path, test_scenes(i).name ));
    if(size(img,3) > 1)
        img = rgb2gray(img);
    end
    img = single(img);
     cur_bboxes = zeros(0,4);
     cur_confidences = zeros(0,1);
     cur_image_ids = cell(0,1);
    for s = 0.04:scale_step:1.05
        
        scaled_img = imresize(img,s);
        hog_img = vl_hog(scaled_img,feature_params.hog_cell_size);
        hog_x = size(hog_img,2);
        hog_y = size(hog_img,1);
        if (hog_x < t_c || hog_y < t_c)
            continue;
        end
        hog_traverse = [];
        hog_x_index = [];
        hog_y_index = [];
        hog_traverse((hog_x - t_c + 1) * (hog_y - t_c + 1),t_c ^ 2 * 31) = 0;
        hog_x_index((hog_x - t_c + 1) * (hog_y - t_c + 1),1) = 0;
        hog_y_index((hog_x - t_c + 1) * (hog_y - t_c + 1),1) = 0;
        for x = 1:1:(hog_x - t_c + 1)
            for y = 1:1:(hog_y - t_c + 1)
                hog_traverse((hog_y - t_c + 1) * (x-1) + y,:) =  reshape(hog_img(y:(y + t_c - 1),x:(x + t_c - 1),:),1,[]) ;
                hog_x_index((hog_y - t_c + 1) * (x-1) + y,1) = x;
                hog_y_index((hog_y - t_c + 1) * (x-1) + y,1) = y;
            end
        end
        hog_traverse_result = (hog_traverse * w) + b;
        good_index = find(hog_traverse_result > confident_thresh);
        if isempty(good_index)
            continue;
        end
        
        
        good_hog = hog_traverse_result(good_index);
        good_x_index = hog_x_index(good_index);
        good_y_index = hog_y_index(good_index);
        
        
        img_x_min = (feature_params.hog_cell_size * (good_x_index -1)) ./s;
        img_y_min = (feature_params.hog_cell_size * (good_y_index -1)) ./s;
        img_x_max = (feature_params.hog_cell_size * (good_x_index -1 + t_c -1)) ./s;
        img_y_max = (feature_params.hog_cell_size * (good_y_index -1 + t_c -1)) ./s;
        img_ids = repmat({test_scenes(i).name}, size(good_index,1), 1);
        
        add_num = size(img_x_min,1);
        
        if isempty(cur_bboxes)
            cur_bboxes(1:add_num,:) = [img_x_min,img_y_min,img_x_max,img_y_max];
            cur_confidences(1:add_num,:) = good_hog;
            cur_image_ids(1:add_num,:) = img_ids;
            
        else
            cur_bboxes(end+1:end+add_num,:) = [img_x_min,img_y_min,img_x_max,img_y_max];
            cur_confidences(end+1:end+add_num,:) = good_hog;
            cur_image_ids(end+1:end+add_num,:) = img_ids;
        end
    end
    
    %You can delete all of this below.
    % Let's create 15 random detections per image
    %     cur_x_min = rand(15,1) * size(img,2);
    %     cur_y_min = rand(15,1) * size(img,1);
    %     cur_bboxes = [cur_x_min, cur_y_min, cur_x_min + rand(15,1) * 50, cur_y_min + rand(15,1) * 50];
    %     cur_confidences = rand(15,1) * 4 - 2; %confidences in the range [-2 2]
    %     cur_image_ids(1:15,1) = {test_scenes(i).name};
    
    %non_max_supr_bbox can actually get somewhat slow with thousands of
    %initial detections. You could pre-filter the detections by confidence,
    %e.g. a detection with confidence -1.1 will probably never be
    %meaningful. You probably _don't_ want to threshold at 0.0, though. You
    %can get higher recall with a lower threshold. You don't need to modify
    %anything in non_max_supr_bbox, but you can.
    
    
    [is_maximum] = non_max_supr_bbox(cur_bboxes, cur_confidences, size(img));
    
    
    cur_confidences = cur_confidences(is_maximum,:);
    cur_bboxes      = cur_bboxes(     is_maximum,:);
    cur_image_ids   = cur_image_ids(  is_maximum,:);
    
    add_num = size(cur_confidences,1);
    bboxes(end+1:end+add_num,:)      = cur_bboxes;
    confidences(end+1:end+add_num,:) = cur_confidences;
    image_ids(end+1:end+add_num,:)   = cur_image_ids;
end




