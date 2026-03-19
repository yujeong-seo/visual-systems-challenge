% TEST
% ON DIFFERENT IMAGE PROCESSING METHODS

clear all; close all;
I = imread('asset/image1-1.jpeg');
f = im2gray(I);

% --- Contrast Enhancement ---
f_contrast = imadjust(f, [0.2 0.7], [0 1]);
figure(1);
imshow(f_contrast);
title('Contrast Enhanced Image');

% --- Histogram ---
figure(2);
subplot(1,2,1); imhist(f);
title('Original Histogram');
subplot(1,2,2); imhist(f_contrast);
title('Contrast Enhanced Histogram');

% --- Gaussian + Otsu ---
w_gauss = fspecial('Gaussian', [5 5], 1.5);
f_smooth = imfilter(f_contrast, w_gauss, 0);
level = graythresh(f_smooth);
BW = imbinarize(f_smooth, level);
BW = imcomplement(BW);
fprintf('Otsu threshold: %.3f\n', level);

% --- Remove regions touching image border (shadows on edges) ---
BW = imclearborder(BW);

% --- Remove relatively small regions ---
cc = bwlabel(BW);
stats = regionprops(cc, 'Area');
all_areas = [stats.Area];

% Discard regions smaller than a fraction of the largest region
largest_area = max(all_areas);
size_threshold = 0.05;  % adjust: discard anything smaller than 5% of largest
BW = bwareaopen(BW, round(largest_area * size_threshold));

fprintf('Largest region area:  %.0f px\n', largest_area);
fprintf('Size threshold (%.0f%%): %.0f px\n', ...
        size_threshold*100, round(largest_area * size_threshold));

figure(3); imshow(BW);
title(sprintf('Binarised (Otsu: %.3f)', level));

edges = edge(BW, 'Canny', 0.3);
figure(4);
imshow(edges);
title('Figure 4: Raw edges');