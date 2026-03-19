clear all
close all
f = imread('assets/random-matches.tif');

g = bwmorph(f, "close", 1);
g = bwmorph(g, "open", 1);
[g1, t] = edge(g, 'canny');
%[g, t] = edge(f, 'canny',[0.08, 0.2], 3);  

se = strel('disk', 1);
g_dil = imdilate(g1, se);

[H, theta, rho] = hough(g_dil);
peaks = houghpeaks(H, 200, ...
    "Threshold", 0.2*max(H(:)), ...
    "NHoodSize",[11 11]);

lines = houghlines(g_dil, theta, rho, peaks, ...
    "FillGap", 5, ...
    "MinLength", 50);

num_lines = length(lines);
num_matches = round(num_lines/2);

figure;
imshow(f); hold on;
for k = 1:length(lines)
    xy = [lines(k).point1; lines(k).point2];
    plot(xy(:,1), xy(:,2), 'r-', 'LineWidth', 1.5);
end
title(sprintf('Hough Lines: %d edges detected → %d matches', num_lines, num_matches));
hold off;

% --- Hough space visualisation ---
figure;
imshow(imadjust(rescale(H)), ...
    'XData', theta, 'YData', rho, ...
    'InitialMagnification', 'fit');
xlabel('\theta'), ylabel('\rho');
title(sprintf('Hough Space | %d peaks found', size(peaks, 1)));
axis on; axis normal; hold on;
plot(theta(peaks(:,2)), rho(peaks(:,1)), 'rs', 'MarkerSize', 5);

montage({f, g, g_dil}, 'Size', [1 3]);
title('(1)Original (2)Canny (3)Dilated');