% Lab 6 Task 6 
% Object recognition using webcam and various neural network models

clear all; close all;
camera = webcam;                            % create camera object for webcam
net = googlenet;                               % change this for other networks
inputSize = net.Layers(1).InputSize(1:2);   % find neural network input size

figure('Name', 'Object Recognition  |  Press Ctrl+C to exit');

last_label  = '—';
last_score  = '—';
last_time   = '—';

while true
    % Countdown: 3, 2, 1 — show previous results while counting
    for count = 3:-1:1
        title({sprintf('Taking photo in... %d  |  Last: %s', count, last_label), ...
               sprintf('Score: %s', last_score), ...
               sprintf('Time:  %s', last_time), ...
               'Press Ctrl+C to exit'});
        drawnow;
        pause(0.5);
    end

    % Capture
    I = snapshot(camera);
    image(I);

    f = imresize(I, inputSize);

    tic;
    [label, score] = classify(net, f);
    elapsed = toc;

    last_label = char(label);
    last_score = num2str(max(score), 2);
    last_time  = sprintf('%.2fs', elapsed);

    title({sprintf('Taking photo in... —  |  %s', last_label), ...
           sprintf('Score: %s', last_score), ...
           sprintf('Time:  %s', last_time), ...
           'Press Ctrl+C to exit'});

    drawnow;
    pause(1.5);
end
