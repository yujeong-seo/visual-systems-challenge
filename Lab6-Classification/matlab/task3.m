% Lab 6 Task 3
% SIFT Feature Detection
clear all; close all;
% I = imread('assets/salvador.tif');
I = imread('assets/cafe_van_gogh.jpg');
f = im2gray(I);
points = detectSIFTFeatures(f);
figure(1); imshow(I);
hold on;
plot(points.selectStrongest(100));
