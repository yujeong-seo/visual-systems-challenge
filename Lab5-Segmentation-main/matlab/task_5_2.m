clear all; close all;
f = imread('assets/peppers.png');    % read image
[M, N, S] = size(f);                  % find image size
F = reshape(f, [M*N S]);            % resize as 1D array of 3 colours
% Separate the three colour channels 
R = F(:,1); G = F(:,2); B = F(:,3);
C = double(F)/255;          % convert to double data type for plotting
figure(1)
scatter3(R, G, B, 1, C);    % scatter plot each pixel as colour dot
xlabel('RED', 'FontSize', 14);
ylabel('GREEN', 'FontSize', 14);
zlabel('BLUE', 'FontSize', 14);
title('Pixel colour in feature vector [R G B]');

% perform k-means clustering
k = 12;
[L,centers]=imsegkmeans(f,k);
% plot the means on the scatter plot
hold
scatter3(centers(:,1),centers(:,2),centers(:,3),100,'black','fill');
title('K-means clustering (k = 12)')

% display the segmented image along with the original
J = label2rgb(L,im2double(centers));
figure(2)
montage({f,J})
title('Segmented image along with the original (k = 12)')