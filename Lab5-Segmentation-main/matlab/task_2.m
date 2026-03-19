clear all
close all
f = imread('../assets/circuit.tif');
f2 = imread('../assets/brain_tumor.jpg');

%[g1, t1] = edge(f2, 'sobel');     % using Sobel
%[g1, t1] = edge(f2, 'log'); 
[g1, t1] = edge(f2, 'canny');
[g2, t2] = edge(f2, 'canny', [0.02, 0.05]);
[g3, t3] = edge(f2, 'canny', [0.05, 0.12]); 
[g4, t4] = edge(f2, 'canny', [0.03, 0.08]); 


montage({f2, g1, g2, g3, g4 }, 'Size', [1 5]);
title('(1): Original image, (2): Canny image (default threshold), (3): Canny image ([0.02, 0.05]), (4): Canny image ([0.05, 0.12)')