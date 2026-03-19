% ITERATION
% CARD DETECTION
% ONLY WORKS FOR RIGHT ANGLE: LANDSCAPE, PORTRAIT RATIOS

clear all; close all;

% Import image
I = imread('../object-size-assets/image1-1.jpeg');
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
stats = regionprops(cc, 'Area', 'BoundingBox', 'Extent');

target_ratio_L = 85.6 / 54;
target_ratio_P = 54  / 85.6;
tolerance      = 0.25;
card_idx       = [];

for i = 1:length(stats)
    bb     = stats(i).BoundingBox;
    ratio  = bb(3) / bb(4);
    extent = stats(i).Extent;

    is_landscape = abs(ratio - target_ratio_L) < tolerance;
    is_portrait  = abs(ratio - target_ratio_P) < tolerance;

    if (is_landscape || is_portrait) && extent > 0.88
        card_idx = [card_idx, i];
    end
end

if isempty(card_idx)
    error('Credit card not detected. Adjust threshold or tolerance.');
end

areas       = arrayfun(@(i) stats(i).Area, card_idx);
[~, best]   = max(areas);
card_region = card_idx(best);
card_mask   = (cc == card_region);

% Corner Detection
card_mask_resized = imresize(card_mask, [size(f,1), size(f,2)], 'nearest');

% Smooth mask to remove staircase edges from rotation
se_smooth        = strel('disk', 3);
card_mask_smooth = imerode(imdilate(card_mask_resized, se_smooth), se_smooth);
card_gray        = uint8(card_mask_smooth) .* f;

corners  = detectHarrisFeatures(card_gray, 'MinQuality', 0.01);
pts      = corners.Location;

% Geometric corner selection — one point per quadrant
bb = stats(card_region).BoundingBox;
card_corners = [bb(1),       bb(2);
                bb(1)+bb(3), bb(2);
                bb(1),       bb(2)+bb(4);
                bb(1)+bb(3), bb(2)+bb(4)];

selected = zeros(4, 2);
for k = 1:4
    dists      = sqrt((pts(:,1) - card_corners(k,1)).^2 + ...
                      (pts(:,2) - card_corners(k,2)).^2);
    [~, idx]   = min(dists);
    selected(k,:) = pts(idx,:);
end

figure(2); imshow(I);
hold on;
plot(selected(:,1), selected(:,2), 'r+', 'MarkerSize', 15, 'LineWidth', 2);
title('Detected Card Corners');
hold off;