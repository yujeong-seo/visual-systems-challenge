% Lab 6 Task 4
% SIFT Matching

clear all; close all;
I1 = imread('assets/cafe_van_gogh.jpg');
I2 = imresize(I1, 0.5);

rotAngle = 20;
I2 = imrotate(I2, rotAngle);

f1 = im2gray(I1);
f2 = im2gray(I2);

points1 = detectSIFTFeatures(f1);
points2 = detectSIFTFeatures(f2);
Nbest = 100;
bestFeatures1 = points1.selectStrongest(Nbest);
bestFeatures2 = points2.selectStrongest(Nbest);

figure(1); imshow(I1);
title('SIFT of original image', 'FontSize', 14);
hold on;
plot(bestFeatures1);
hold off;

figure(2); imshow(I2);
title('SIFT of downscaled image', 'FontSize', 14);
hold on;
plot(bestFeatures2);
hold off;

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

