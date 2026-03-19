% Main code for the Object Size Measurement
% UI Container and calls the function

clear all; close all;

% UI Setup
fig = uifigure('Name', 'Object Size Measurement', 'Position', [100 100 1100 700]);

% Left Panel
left_panel = uipanel(fig, 'Position', [10 10 430 680], 'Title', 'Image Input');

ax_input = uiaxes(left_panel, 'Position', [10 58 410 542]);
ax_input.XTick = []; ax_input.YTick = [];

lbl_filename = uilabel(left_panel, 'Position', [10 12 410 20], ...
                       'Text', 'Select the image using the button above', ...
                       'HorizontalAlignment', 'center', 'FontAngle', 'italic');

% Right Panel
right_panel = uipanel(fig, 'Position', [450 10 640 680], 'Title', 'Results');

% Measurement Results header + unit toggle (outside tabs, applies to all objects)
uilabel(right_panel, 'Position', [10 620 220 26], ...
        'Text', 'Measurement Results', 'FontSize', 13, 'FontWeight', 'bold');

bg_unit = uibuttongroup(right_panel, 'Position', [370 617 240 32], ...
                        'BorderType', 'none');
uitogglebutton(bg_unit, 'Text', 'mm', 'Position', [5   4 110 24], 'Value', 1);
uitogglebutton(bg_unit, 'Text', 'cm', 'Position', [120 4 110 24], 'Value', 0);

% Tab group — one tab per detected object
tab_group = uitabgroup(right_panel, 'Position', [5 8 628 600]);

% Unit toggle callback
bg_unit.SelectionChangedFcn = @(src,event) update_units(src, fig);

% Buttons
btn_process = uibutton(left_panel, 'push', ...
                       'Text', 'Detect Object →', ...
                       'Position', [175 610 150 35], ...
                       'Enable', 'off', ...
                       'ButtonPushedFcn', @(btn,event) process_image( ...
                           ax_input, tab_group, bg_unit, fig));

btn_upload = uibutton(left_panel, 'push', ...
                      'Text', 'Select Image', ...
                      'Position', [15 610 150 35], ...
                      'ButtonPushedFcn', @(btn,event) upload_image( ...
                          ax_input, btn_process, lbl_filename, fig));
