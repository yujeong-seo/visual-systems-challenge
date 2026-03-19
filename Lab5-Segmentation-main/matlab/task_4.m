clear all; close all;
f = imread('assets/yeast-cells.tif');

% Otsu's thresholding
t_otsu = graythresh(f);   % Otsu's optimal threshold
g_otsu = imbinarize(f, t_otsu);

% Variable thresholding
w = 25;    % Window size 15x15
a = 0.4;   % Standard deviation weight
b = 0.9;   % Mean weight

localngb = ones(w, w);
m = imfilter(double(f), localngb/sum(localngb(:)), 'replicate');
sigma = stdfilt(double(f), localngb);
T = a * sigma + b * m;

g_variable = double(f) >= T;

se = strel('disk', 4);
g_cleaned = imclose (g_variable, se);

figure(1)
montage({f, g_variable, g_cleaned}, 'Size', [1 3]);
title('(1): Original image, (2): Variable Threshold (a = 0.4, b = 0.9), (3): Cleaned Variable Threshold');
