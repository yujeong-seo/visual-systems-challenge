clear all
close all
f = imread('assets/f14.png');
% Using Canny edge detection to detect jet edges
fEdge = edge(f,'Canny',[0.01, 0.04]);

% Thicken all edges to ensure the jet boundary is fully closed
se = strel('disk', 1);
fDilate = imdilate(fEdge, se);

% Fill the interior of the jet boundary 
fFill = imfill(fDilate, 'holes');
% Keeps only the largest connected white object (jet)
fClean = bwareafilt(fFill, 1);

% Close the gaps in jet boundary
se1 = strel('disk', 2);
fClose = imclose(fClean, se1);

% Fill one more time to ensure all jet interior is covered
fFinal = imfill(fClose, 'holes');


montage({f, fEdge, fFill, fClean, fClose, fFinal}, 'Size',[2 3]);
title('Top: 1. Original image, 2. Image with Canny detector, 3. Image with 1st Fill, Bottom: 1. Cleaned image, 2. Closed image, 3. Final image')