function [I_homo, BW_homo, px_per_mm_h] = homography(I_straight, BW_straight, ...
                                                      selected_str, card_stats, ...
                                                      px_per_mm, target_ratio, tolerance)
% HOMOGRAPHY  Correct perspective distortion using detected card corners.
%
%   [I_homo, BW_homo, px_per_mm_h] = homography(I_straight, BW_straight,
%       selected_str, card_stats, px_per_mm, target_ratio, tolerance)
%
%   Inputs:
%     I_straight   - rotation-corrected colour image  [H x W x 3]
%     BW_straight  - rotation-corrected binary mask   [H x W]
%     selected_str - 4x2 card corner coordinates in straightened image space
%     card_stats   - regionprops struct for card (MajorAxisLength, MinorAxisLength)
%     px_per_mm    - initial scale factor [px/mm]
%     target_ratio - expected aspect ratio (MajorAxisLength / MinorAxisLength)
%     tolerance    - ratio tolerance for card re-detection in corrected image
%
%   Outputs:
%     I_homo       - homography-corrected colour image
%     BW_homo      - homography-corrected, cleaned binary image
%     px_per_mm_h  - scale factor re-estimated from corrected card

    % Order corners: TL, TR, BR, BL (sorted by angle from centroid)
    cx = mean(selected_str(:,1));
    cy = mean(selected_str(:,2));
    [~, order] = sort(atan2(selected_str(:,2) - cy, selected_str(:,1) - cx));
    pts = selected_str(order, :);
    src_pts = [pts(4,:); pts(1,:); pts(2,:); pts(3,:)];  % TL TR BR BL

    % Destination (fronto-parallel) card dimensions 
    if card_stats.MajorAxisLength >= card_stats.MinorAxisLength
        card_w_px = 85.6 * px_per_mm;
        card_h_px = 54.0 * px_per_mm;
    else
        card_w_px = 54.0 * px_per_mm;
        card_h_px = 85.6 * px_per_mm;
    end

    dst_pts = [0,         0;
               card_w_px, 0;
               card_w_px, card_h_px;
               0,         card_h_px];

    % Projective transform 
    tform = fitgeotrans(src_pts, dst_pts, 'projective');

    % Output canvas sized to contain the full warped image 
    [rows, cols, ~] = size(I_straight);
    img_corners  = [1, 1; cols, 1; cols, rows; 1, rows];
    corners_t    = transformPointsForward(tform, img_corners);

    x_min = min([corners_t(:,1); 0]);
    y_min = min([corners_t(:,2); 0]);
    x_max = max([corners_t(:,1); card_w_px]);
    y_max = max([corners_t(:,2); card_h_px]);

    output_view = imref2d([round(y_max - y_min), round(x_max - x_min)], ...
                           [x_min, x_max], [y_min, y_max]);

    % Warp colour and binary images
    I_homo  = imwarp(I_straight,  tform, 'OutputView', output_view);
    BW_warp = imwarp(BW_straight, tform, 'OutputView', output_view);

    % Clean up warped binary
    BW_homo = imfill(BW_warp, 'holes');
    BW_homo = bwareaopen(BW_homo, 500);

    % Re-estimate scale from card in corrected image
    cc_h    = bwlabel(BW_homo);
    stats_h = regionprops(cc_h, 'Area', 'MajorAxisLength', 'MinorAxisLength', 'Extent');

    card_idx_h = [];
    for i = 1:length(stats_h)
        if stats_h(i).MinorAxisLength == 0; continue; end
        r = stats_h(i).MajorAxisLength / stats_h(i).MinorAxisLength;
        if abs(r - target_ratio) < tolerance && stats_h(i).Extent > 0.88
            card_idx_h = [card_idx_h, i];
        end
    end

    if isempty(card_idx_h)
        px_per_mm_h = px_per_mm;  % fall back to original scale
    else
        areas_h     = arrayfun(@(i) stats_h(i).Area, card_idx_h);
        [~, best_h] = max(areas_h);
        ch          = card_idx_h(best_h);
        px_per_mm_h = (stats_h(ch).MajorAxisLength / 85.6 + ...
                       stats_h(ch).MinorAxisLength  / 54.0) / 2;
    end
end
