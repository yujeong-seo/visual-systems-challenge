% Lab 6 Task 1 
% Image resizing
clear all; close all;
f0 = imread('assets/cafe_van_gogh.jpg');

% Wrong way: Dropping samples
f1 = f0(1:2:end,1:2:end,:);
f2 = f1(1:2:end,1:2:end,:);
f3 = f2(1:2:end,1:2:end,:);
f4 = f3(1:2:end,1:2:end,:);
f5 = f4(1:2:end,1:2:end,:);
figure(1)
montage({f0,f1,f2,f3,f4,f5},'Size',[2 3]);
title('Wrong way of subsampling', 'FontSize', 14);

% Correct way: imresize which first filter the image before dropping samples
f_1 = imresize(f0, 0.5);
f_2 = imresize(f_1, 0.5);
f_3 = imresize(f_2, 0.5);
f_4 = imresize(f_3, 0.5);
f_5 = imresize(f_4, 0.5);
figure(2)
montage({f0,f_1,f_2,f_3,f_4,f_5},'Size',[2 3]);
title('Correct way of subsampling(imresize)', 'FontSize', 14);
