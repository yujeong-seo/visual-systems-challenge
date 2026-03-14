% Lab 6 Task 5
% SIFT vs. SURF

clear all; close all;
I1 = imread('assets/traffic_1.jpg');
I2 = imread('assets/traffic_2.jpg');
f1 = im2gray(I1);
f2 = im2gray(I2);

points1 = detectSIFTFeatures(f1);
points2 = detectSIFTFeatures(f2);
Nbest = 100;
bestFeatures1 = points1.selectStrongest(Nbest);
bestFeatures2 = points2.selectStrongest(Nbest);

% Scale and rotation invariance
% [features1, valid_points1] = extractFeatures(f1, points1);
% [features2, valid_points2] = extractFeatures(f2, points2);

[features1, valid_points1] = extractFeatures(f1, bestFeatures1);
[features2, valid_points2] = extractFeatures(f2, bestFeatures2);

indexPairs = matchFeatures(features1, features2, 'Unique', true);

matchedPoints1 = valid_points1(indexPairs(:,1),:);
matchedPoints2 = valid_points2(indexPairs(:,2),:);
figure(3);
showMatchedFeatures(f1,f2,matchedPoints1,matchedPoints2);
title('SIFT Match of Video Sequence', 'FontSize', 14);

