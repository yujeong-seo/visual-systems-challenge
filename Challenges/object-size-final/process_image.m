% Main image processing function
% Detects the object and the card

function process_image(ax_input, tab_group, bg_unit, fig)

    I = getappdata(fig, 'I_loaded');
    if isempty(I); return; end

    f = im2gray(I);

    % Contrast Enhancement
    f_contrast = imadjust(f, [0.2 0.7], [0 1]);

    % Gaussian + Otsu
    w_gauss = fspecial('Gaussian', [5 5], 1.5);
    f_smooth = imfilter(f_contrast, w_gauss, 0);
    level = graythresh(f_smooth);
    BW = imbinarize(f_smooth, level);
    BW       = imcomplement(BW);

    % Morphological Cleanup
    BW = imclearborder(BW);
    BW = bwmorph(BW, 'clean');
    BW = imopen(BW,  strel('disk', 2));
    BW = imclose(BW, strel('disk', 4));
    BW = imfill(BW, 'holes');

    cc = bwlabel(BW);
    stats_tmp = regionprops(cc, 'Area');
    largest = max([stats_tmp.Area]);
    BW = bwareaopen(BW, round(largest * 0.05));

    % Card Detection
    cc = bwlabel(BW);
    stats = regionprops(cc, 'Area', 'BoundingBox', 'Extent', ...
                            'MajorAxisLength', 'MinorAxisLength', 'Orientation');

    target_ratio = 85.6 / 54;
    min_area = largest * 0.05;

    % Attempt 1: standard thresholds
    tolerance = 0.20;
    extent_thresh = 0.88;
    card_idx = find_card(stats, cc, min_area, target_ratio, tolerance, extent_thresh);
    use_homography = false;

    if isempty(card_idx)
        % Attempt 2: relaxed thresholds for a heavily distorted image
        tolerance = 0.30;
        extent_thresh = 0.70;
        card_idx = find_card(stats, cc, min_area, target_ratio, tolerance, extent_thresh);
        if isempty(card_idx)
            uialert(fig, 'Credit card not detected. Adjust image or lighting.', 'Detection Failed');
            return
        end
        use_homography = true;
    end

    areas = arrayfun(@(i) stats(i).Area, card_idx);
    [~, best] = max(areas);
    card_region = card_idx(best);
    card_mask = (cc == card_region);

    % Straighten card for corner detection + scale
    angle = normalise_angle(stats(card_region).Orientation);
    card_mask_straight = imrotate(card_mask, -angle, 'loose');
    f_straight = imrotate(f, -angle, 'loose');

    card_mask_resized = imresize(card_mask_straight, ...
                                 [size(f_straight,1), size(f_straight,2)], 'nearest');
    se_smooth = strel('disk', 3);
    card_mask_smooth = imerode(imdilate(card_mask_resized, se_smooth), se_smooth);
    card_gray = uint8(card_mask_smooth) .* f_straight;

    corners = detectHarrisFeatures(card_gray, 'MinQuality', 0.01);
    pts = corners.Location;
    stats_bb = regionprops(card_mask_resized, 'BoundingBox');
    bb = stats_bb(1).BoundingBox;

    card_corners = [bb(1),       bb(2);
                    bb(1)+bb(3), bb(2);
                    bb(1),       bb(2)+bb(4);
                    bb(1)+bb(3), bb(2)+bb(4)];

    % Find nearest Harris point to each expected corner (in straightened space)
    selected_str = zeros(4, 2);
    for k = 1:4
        dists             = sqrt((pts(:,1)-card_corners(k,1)).^2 + ...
                                  (pts(:,2)-card_corners(k,2)).^2);
        [~, idx]          = min(dists);
        selected_str(k,:) = pts(idx,:);
    end

    % Map corners back to original image coordinates
    c_str  = [(size(f_straight,2)+1)/2, (size(f_straight,1)+1)/2];
    c_orig = [(size(f,2)+1)/2,          (size(f,1)+1)/2];
    selected_orig = zeros(4, 2);
    for k = 1:4
        dp = selected_str(k,:) - c_str;
        selected_orig(k,:) = [cosd(angle)*dp(1) + sind(angle)*dp(2), ...
                              -sind(angle)*dp(1) + cosd(angle)*dp(2)] + c_orig;
    end

    % Overlay corners on the original input image
    imshow(I, 'Parent', ax_input);
    hold(ax_input, 'on');
    plot(ax_input, selected_orig(:,1), selected_orig(:,2), ...
         'r+', 'MarkerSize', 15, 'LineWidth', 2);
    hold(ax_input, 'off');

    % Scale factor
    px_per_mm_major = stats(card_region).MajorAxisLength / 85.6;
    px_per_mm_minor = stats(card_region).MinorAxisLength / 54.0;
    px_per_mm       = (px_per_mm_major + px_per_mm_minor) / 2;

    % Homography correction: when standard detection fails
    if use_homography
        BW_straight = imrotate(BW, -angle, 'loose');
        I_straight  = imrotate(I,  -angle, 'loose');
        [I, BW, px_per_mm] = homography(I_straight, BW_straight, selected_str, ...
                                         stats(card_region), px_per_mm, ...
                                         target_ratio, tolerance);
        f = im2gray(I);

        % Show corrected image in the input panel
        imshow(I, 'Parent', ax_input);

        % Re-label corrected binary and re-detect card
        cc    = bwlabel(BW);
        stats = regionprops(cc, 'Area', 'BoundingBox', 'Extent', ...
                                'MajorAxisLength', 'MinorAxisLength', 'Orientation');
        if isempty(stats)
            uialert(fig, 'No regions detected after homography correction.', 'Error');
            return
        end

        largest_h = max([stats.Area]);
        min_area  = largest_h * 0.05;
        card_idx = find_card(stats, cc, min_area, target_ratio, tolerance, extent_thresh);

        if isempty(card_idx)
            uialert(fig, 'Card not re-detected after correction. Scale may be inaccurate.', 'Warning');
        else
            areas_h     = arrayfun(@(i) stats(i).Area, card_idx);
            [~, best_h] = max(areas_h);
            card_region = card_idx(best_h);
        end
    end

    % All Non-card Object Detection
    all_regions = 1:length(stats);
    obj_regions = all_regions(all_regions ~= card_region);

    if isempty(obj_regions)
        uialert(fig, 'No objects detected other than the credit card.', 'No Objects');
        return
    end

    obj_areas = arrayfun(@(i) stats(i).Area, obj_regions);
    [~, sort_idx] = sort(obj_areas, 'descend');
    obj_regions = obj_regions(sort_idx);

    % Clear previous tabs and measurements
    delete(tab_group.Children);
    meas_all = struct([]);

    for k = 1:length(obj_regions)
        obj_region = obj_regions(k);
        obj_mask = (cc == obj_region);

        % Straighten object
        obj_angle = normalise_angle(stats(obj_region).Orientation);
        obj_straight = imrotate(obj_mask, -obj_angle, 'loose');
        I_obj_straight = imrotate(I, -obj_angle, 'loose');

        obj_stats_str = regionprops(obj_straight, 'BoundingBox', ...
                                                   'MajorAxisLength', ...
                                                   'MinorAxisLength');
        obj_bb = obj_stats_str(1).BoundingBox;
        obj_long_mm = obj_stats_str(1).MajorAxisLength / px_per_mm;
        obj_short_mm = obj_stats_str(1).MinorAxisLength / px_per_mm;

        obj_stats_orig = regionprops(obj_mask, 'Area', 'Perimeter');
        obj_area_mm2 = obj_stats_orig(1).Area / (px_per_mm^2);
        obj_perim_mm = obj_stats_orig(1).Perimeter / px_per_mm;

        % Crop with padding
        pad = 20;
        x1  = max(1,   round(obj_bb(2) - pad));
        y1  = max(1,   round(obj_bb(1) - pad));
        x2  = min(size(I_obj_straight,1), round(obj_bb(2)+obj_bb(4)+pad));
        y2  = min(size(I_obj_straight,2), round(obj_bb(1)+obj_bb(3)+pad));

        I_crop = I_obj_straight(x1:x2, y1:y2, :);
        obj_bin_crop = ~obj_straight(x1:x2, y1:y2);
        bb_crop = [obj_bb(1)-y1+1, obj_bb(2)-x1+1, obj_bb(3), obj_bb(4)];

        % --- Create tab for this object ---
        tab = uitab(tab_group, 'Title', sprintf('Object %d', k));

        ax_bin_k = uiaxes(tab, 'Position', [8 298 288 280]);
        ax_bin_k.XTick = []; ax_bin_k.YTick = [];
        title(ax_bin_k, 'Binarised object');

        ax_obj_k = uiaxes(tab, 'Position', [308 298 288 280]);
        ax_obj_k.XTick = []; ax_obj_k.YTick = [];
        title(ax_obj_k, 'Object Image');

        uilabel(tab, 'Position', [8 258 200 26], 'Text', 'Bounding box', ...
                'FontSize', 12, 'FontColor', [0 0.45 0.74], 'FontAngle', 'italic');
        lbl_long_k  = uilabel(tab, 'Position', [8 230 380 26], ...
                              'Text', 'Long side:', 'FontSize', 12);
        lbl_short_k = uilabel(tab, 'Position', [8 202 380 26], ...
                              'Text', 'Short side:', 'FontSize', 12);

        uilabel(tab, 'Position', [8 168 200 26], 'Text', 'Object', ...
                'FontSize', 12, 'FontColor', [0 0.45 0.74], 'FontAngle', 'italic');
        lbl_perim_k = uilabel(tab, 'Position', [8 140 380 26], ...
                              'Text', 'Perimeter:', 'FontSize', 12);
        lbl_area_k  = uilabel(tab, 'Position', [8 112 380 26], ...
                              'Text', 'Area:', 'FontSize', 12);
        lbl_scale_k = uilabel(tab, 'Position', [8 58 380 26], ...
                              'Text', 'Scale:', 'FontSize', 12);

        % Display images
        imshow(obj_bin_crop, 'Parent', ax_bin_k);
        imshow(I_crop, 'Parent', ax_obj_k);
        hold(ax_obj_k, 'on');
        rectangle(ax_obj_k, 'Position', bb_crop, 'EdgeColor', 'r', 'LineWidth', 2);
        text(ax_obj_k, bb_crop(1)+bb_crop(3)/2, bb_crop(2)-8, ...
             sprintf('%.1f mm', obj_long_mm), ...
             'Color', 'r', 'FontSize', 10, 'HorizontalAlignment', 'center');
        text(ax_obj_k, bb_crop(1)+bb_crop(3)+5, bb_crop(2)+bb_crop(4)/2, ...
             sprintf('%.1f mm', obj_short_mm), ...
             'Color', 'r', 'FontSize', 10, 'HorizontalAlignment', 'left');
        hold(ax_obj_k, 'off');

        % Store measurements and label handles
        meas_all(k).px_per_mm    = px_per_mm;
        meas_all(k).obj_long_mm  = obj_long_mm;
        meas_all(k).obj_short_mm = obj_short_mm;
        meas_all(k).obj_perim_mm = obj_perim_mm;
        meas_all(k).obj_area_mm2 = obj_area_mm2;
        meas_all(k).lbl_scale    = lbl_scale_k;
        meas_all(k).lbl_long     = lbl_long_k;
        meas_all(k).lbl_short    = lbl_short_k;
        meas_all(k).lbl_perim    = lbl_perim_k;
        meas_all(k).lbl_area     = lbl_area_k;
    end

    setappdata(fig, 'meas_all', meas_all);
    update_units(bg_unit, fig);
end


% Local function: indices of regions that match credit-card aspect ratio and extent
function card_idx = find_card(stats, cc, min_area, target_ratio, tolerance, extent_thresh)
    card_idx = [];
    for i = 1:length(stats)
        if stats(i).Area < min_area || stats(i).MinorAxisLength == 0
            continue
        end
        ratio           = stats(i).MajorAxisLength / stats(i).MinorAxisLength;
        region_mask     = (cc == i);
        angle           = normalise_angle(stats(i).Orientation);
        region_straight = imrotate(region_mask, -angle, 'loose');
        stats_str       = regionprops(region_straight, 'Extent');
        extent_straight = stats_str(1).Extent;
        if abs(ratio - target_ratio) < tolerance && extent_straight > extent_thresh
            card_idx = [card_idx, i];
        end
    end
end
