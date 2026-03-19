% ITERATION
% IN ADDITION TO c1_2.m 
% SECOND OBJECT MEASUREMENT

clear all; close all;

% Import image
I = imread('../object-size-assets/image2.jpeg');
f = im2gray(I);

% Image processing
% Contrast enhancement
f_contrast = imadjust(f, [0.2 0.7], [0 1]);

% Gaussian + Otsu for clear binarisation
w_gauss = fspecial('Gaussian', [5 5], 1.5);
f_smooth = imfilter(f_contrast, w_gauss, 0);
level = graythresh(f_smooth);
BW = imbinarize(f_smooth, level);
BW = imcomplement(BW);

% Remove shadows (regions touching border) 
BW = imclearborder(BW);

% Morphological operation
BW = bwmorph(BW, 'clean');
se_open = strel('disk', 2);
se_close = strel('disk', 4);
BW = imopen(BW,  se_open);
BW = imclose(BW, se_close);
BW = imfill(BW, 'holes');

% Remove relatively small regions: remaining noises
cc         = bwlabel(BW);
stats      = regionprops(cc, 'Area');
all_areas  = [stats.Area];
largest    = max(all_areas);
BW         = bwareaopen(BW, round(largest * 0.05));

figure(1); imshow(BW);
title('Clean Binarised Image');

% Card Detection
cc = bwlabel(BW);
stats = regionprops(cc, 'Area', 'BoundingBox', 'Extent', ...
                        'MajorAxisLength', 'MinorAxisLength', 'Orientation');

target_ratio = 85.6 / 54;
tolerance      = 0.25;
card_idx       = [];

% for i = 1:length(stats)
%     ratio  = stats(i).MajorAxisLength / stats(i).MinorAxisLength;
%     extent = stats(i).Extent;
% 
%     if abs(ratio - target_ratio) < tolerance && extent > 0.88
%         card_idx = [card_idx, i];
%     end
% end

min_area = largest * 0.05;

for i = 1:length(stats)
    if stats(i).Area < min_area || stats(i).MinorAxisLength == 0
        continue
    end

    ratio = stats(i).MajorAxisLength / stats(i).MinorAxisLength;

    % Straighten region by rotating by its orientation angle
    region_mask  = (cc == i);
    angle = normalise_angle(stats(i).Orientation);
    region_straight = imrotate(region_mask, -angle, 'loose');

    % Measure extent on straightened region
    stats_straight = regionprops(region_straight, 'Extent');
    extent_straight = stats_straight(1).Extent;

    fprintf('Region %d: ratio=%.3f  raw_extent=%.3f  straight_extent=%.3f  angle=%.1f\n', ...
            i, ratio, stats(i).Extent, extent_straight, angle);

    if abs(ratio - target_ratio) < tolerance && extent_straight > 0.88
        card_idx = [card_idx, i];
        fprintf('  --> CANDIDATE\n');
    end
end


if isempty(card_idx)
    error('Credit card not detected. Adjust threshold or tolerance.');
end

areas       = arrayfun(@(i) stats(i).Area, card_idx);
[~, best]   = max(areas);
card_region = card_idx(best);
card_mask   = (cc == card_region);

% --- Straighten card mask using orientation ---
angle = normalise_angle(stats(card_region).Orientation);
card_mask_straight = imrotate(card_mask, -angle, 'loose');
f_straight         = imrotate(f, -angle, 'loose');
I_straight         = imrotate(I, -angle, 'loose');

% --- Corner Detection on straightened mask ---
card_mask_resized = imresize(card_mask_straight, ...
                             [size(f_straight,1), size(f_straight,2)], 'nearest');

% Smooth mask to remove staircase edges
se_smooth        = strel('disk', 3);
card_mask_smooth = imerode(imdilate(card_mask_resized, se_smooth), se_smooth);
card_gray        = uint8(card_mask_smooth) .* f_straight;

corners = detectHarrisFeatures(card_gray, 'MinQuality', 0.01);
pts     = corners.Location;

% Recompute stats on straightened mask for correct bounding box
stats_straight = regionprops(card_mask_resized, 'BoundingBox');
bb             = stats_straight(1).BoundingBox;

% Geometric corner selection — one point per quadrant
card_corners = [bb(1),       bb(2);
                bb(1)+bb(3), bb(2);
                bb(1),       bb(2)+bb(4);
                bb(1)+bb(3), bb(2)+bb(4)];

selected = zeros(4, 2);
for k = 1:4
    dists         = sqrt((pts(:,1) - card_corners(k,1)).^2 + ...
                         (pts(:,2) - card_corners(k,2)).^2);
    [~, idx]      = min(dists);
    selected(k,:) = pts(idx,:);
end

figure(2); imshow(I_straight);
hold on;
plot(selected(:,1), selected(:,2), 'r+', 'MarkerSize', 15, 'LineWidth', 2);
title('Detected Card Corners (Straightened)');
hold off;

% --- Step 3: Object Measurement ---

% Scale factor from card
px_per_mm_major = stats(card_region).MajorAxisLength / 85.6;
px_per_mm_minor = stats(card_region).MinorAxisLength / 54.0;
px_per_mm       = (px_per_mm_major + px_per_mm_minor) / 2;

% --- Identify object region (non-card) ---
all_regions = 1:length(stats);
obj_regions = all_regions(all_regions ~= card_region);

% Select largest non-card region as the object
obj_areas  = arrayfun(@(i) stats(i).Area, obj_regions);
[~, best]  = max(obj_areas);
obj_region = obj_regions(best);
obj_mask   = (cc == obj_region);

% --- Object Bounding Box (orientation-corrected) ---
obj_angle = normalise_angle(stats(obj_region).Orientation);
obj_straight = imrotate(obj_mask, -obj_angle, 'loose');
I_obj_straight = imrotate(I, -obj_angle, 'loose');

obj_stats_straight = regionprops(obj_straight, 'BoundingBox', ...
                                               'MajorAxisLength', ...
                                               'MinorAxisLength');
obj_bb = obj_stats_straight(1).BoundingBox;

% Bounding box dimensions in mm
obj_long_px  = obj_stats_straight(1).MajorAxisLength;
obj_short_px = obj_stats_straight(1).MinorAxisLength;
obj_long_mm  = obj_long_px  / px_per_mm;
obj_short_mm = obj_short_px / px_per_mm;

% --- Perimeter and Area (from original BW, no rotation needed) ---
obj_stats_orig = regionprops(obj_mask, 'Area', 'Perimeter');
obj_area_mm2   = obj_stats_orig(1).Area     / (px_per_mm^2);
obj_perim_mm   = obj_stats_orig(1).Perimeter /  px_per_mm;

% --- Label bounding box on image ---
figure(3); imshow(I_obj_straight);
hold on;

% Draw bounding box
rectangle('Position', obj_bb, 'EdgeColor', 'r', 'LineWidth', 2);

% Label long side
text(obj_bb(1) + obj_bb(3)/2, obj_bb(2) - 10, ...
     sprintf('%.1f mm', obj_long_mm), ...
     'Color', 'r', 'FontSize', 12, 'HorizontalAlignment', 'center');

% Label short side
text(obj_bb(1) + obj_bb(3) + 10, obj_bb(2) + obj_bb(4)/2, ...
     sprintf('%.1f mm', obj_short_mm), ...
     'Color', 'r', 'FontSize', 12, 'HorizontalAlignment', 'left');

title('Object Measurement');
hold off;

% --- Print all results ---
fprintf('\n--- Measurement Results ---\n');
fprintf('Scale factor:       %.4f px/mm\n',  px_per_mm);
fprintf('Object long side:   %.2f mm\n',     obj_long_mm);
fprintf('Object short side:  %.2f mm\n',     obj_short_mm);
fprintf('Object perimeter:   %.2f mm\n',     obj_perim_mm);
fprintf('Object area:        %.2f mm^2\n',   obj_area_mm2);

function angle_norm = normalise_angle(angle)
    % Rotate by smallest angle to nearest 90 degree position
    angle_norm = mod(angle + 45, 90) - 45;
end
