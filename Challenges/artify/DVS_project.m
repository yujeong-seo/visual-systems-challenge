function Artify()
    fig = uifigure('Name','Artify Your Image', 'Position', [100 100 1000 700]);
    
    % Global variables
    originalImg = [];
    paintLayer = [];  % Cached K-means colours (Fixed variable name)
    grayImg = [];
    smoothImg = [];
    paintPalette = [];
    kmeansLabels = [];  % Cached the pixel groupings to isolate colours
     
    controlPanel = uipanel(fig, 'Position', [0 550 1000 160], 'BorderType','none');
    
    % Image upload button
    btn = uibutton(controlPanel, 'Position',[20, 100, 120, 40], ...
        'Text', '1. Upload Photo', ...
        'FontSize', 14, ...
        'ButtonPushedFcn', @uploadPhoto);
       
    % Art Style Dropdown
    uilabel(controlPanel, 'Position', [180, 105, 70, 30], 'Text', '2. Style:', 'FontSize', 12);
    styleDropdown = uidropdown(controlPanel, 'Position', [250, 105, 110, 30], ...
           'Items', {'Comic', 'Pointillism', 'Stained Glass'}, ...
           'ValueChangedFcn', @updateArt);
   
    % Change slider to adjust stroke thickness
    app.SliderLabel = uilabel(controlPanel, 'Position', [400, 105, 150, 30], ...
                              'Text', '3. Parameter:', 'FontSize', 12);
    thicknessSlider = uislider(controlPanel, 'Position', [550, 115, 200, 3], ...
                                    'Limits', [1 8], 'Value', 4, ...
                                    'ValueChangedFcn', @updateArt);
    % K-Means Colors Dropdown
    uilabel(controlPanel, 'Position', [20, 25, 130, 30], 'Text', '4. Number of Colors:', 'FontSize', 12);
    kDropdown = uidropdown(controlPanel, 'Position', [150, 25, 60, 30], ...
           'Items', {'5', '7', '10'}, 'Value', '7', ...
           'ValueChangedFcn', @updateKMeans);       
    
    % 5. Theme Palette Display
    uilabel(controlPanel, 'Position', [240, 25, 130, 30], 'Text', '5. Main Color Theme (Click to isolate):', 'FontSize', 12);
    axPalette = uiaxes(controlPanel, 'Position', [380, 15, 350, 50]);
    axPalette.XTick = []; axPalette.YTick = [];
    axOriginal = uiaxes(fig, 'Position', [20, 50, 450, 480]);
    title(axOriginal, 'Original Image');
    axOriginal.XTick = []; axOriginal.YTick = [];
    
    axComic = uiaxes(fig, 'Position', [500, 50, 450, 480]);
    title(axComic, 'Artified Image');
    axComic.XTick = []; axComic.YTick = [];
    
    function uploadPhoto(~,~)
        [file, path] = uigetfile({'*.jpg;*.png;*.jpeg', 'Image Files'});
        if isequal(file, 0)
            return; % User canceled the file selection
        end
        originalImg = imread(fullfile(path, file));
        
        imshow(originalImg, 'Parent', axOriginal);
        title(axOriginal, 'Original Image');
        title(axComic, 'Processing...');
        drawnow;
        
        smoothImg = imguidedfilter(originalImg);
        grayImg = rgb2gray(smoothImg);
         
        % Trigger the K-means calculation automatically
        updateKMeans([], []);  
    end
    function updateKMeans(~,~)
        if isempty(smoothImg)
            return;
        end
        
        title(axComic, 'Calculating Colors... Please Wait');
        drawnow; 
        
        % Get the 'k' number from dropdown 
        k = str2double(kDropdown.Value);
        
        % Run clustering
        [kmeansLabels, centers] = imsegkmeans(smoothImg, k);
        paintPalette = double(centers)/255;
        paintLayer = label2rgb(kmeansLabels, paintPalette);
        
        cla(axPalette); % Clear old colors
        hold(axPalette, 'on');
        width = 1 / k;
        for c = 1:k
            % Draw a colored rectangle for each K-means center
            rect = rectangle(axPalette, 'Position', [(c-1)*width, 0, width, 1], ...
                      'FaceColor', paintPalette(c,:), 'EdgeColor', 'none');
            
            rect.UserData = c;
            rect.ButtonDownFcn = @isolateColor;
        end
        xlim(axPalette, [0, 1]); ylim(axPalette, [0, 1]);
        hold(axPalette, 'off');
        
        % Trigger the final art render
        updateArt([], []);
    end
    function isolateColor(src, ~)
        if isempty(originalImg) || isempty(kmeansLabels)
            return;
        end
        title(axComic, 'Applying Selective Color...');
        drawnow;
        clickedColorID = src.UserData;
        bw_bg = imadjust(rgb2gray(originalImg));
        bw_bg_3D = repmat(bw_bg, [1, 1, 3]);
        colorMask = (kmeansLabels == clickedColorID);
        colorMask_3D = repmat(colorMask, [1, 1, 3]);
        final_art = bw_bg_3D;
        final_art(colorMask_3D) = originalImg(colorMask_3D);
        imshow(final_art, 'Parent', axComic);
        title(axComic, 'Selective Color Effect');
    end
    function updateArt(~,~)
        if isempty(originalImg)
            return;
        end
        title(axComic, 'Rendering Art... Please Wait');
        drawnow; 
        
        currentStyle = styleDropdown.Value;
        currentRadius = round(thicknessSlider.Value);
        final_art = [];
        
        if strcmp(currentStyle, 'Comic') 
            % Comic Style
            app.SliderLabel.Text = '4. Ink Line Thickness:';
            % Extract MatLab's recommended threshold
            [~, defaultThresh] = edge(grayImg, 'canny');
            
            strictThresh = min(1.0, defaultThresh * 2.5);
            edges = edge(grayImg, 'canny', strictThresh, 3.5);
            clean_edges = bwareaopen(edges, 80);
            se = strel('disk', currentRadius);
            thick_edges = imdilate(clean_edges, se);
            
            final_art = paintLayer;
            edge_mask_3D = repmat(thick_edges, [1, 1, 3]);
            final_art(edge_mask_3D) = 0;    % Force edges to be black   
            
            title(axComic, 'Comic Art');
            
        elseif strcmp(currentStyle, 'Pointillism')
            % Impressionist Pointillism Style
            app.SliderLabel.Text = '4. Paint Dot Size:';
            
            [rows, cols, ~] = size(originalImg);
            canvas = 255 * ones(rows, cols, 3, 'uint8');
            
            numStrokes = 120000;
            
            randY = randi([1, rows], numStrokes, 1);
            randX = randi([1, cols], numStrokes, 1);
            
            % Create circle with 3 pre-built brush sizes
            % Scales the 20:12:8 ratio based on the slider 
            brushes = cell(1, 3);
            radii = round([5, 3, 2] .* currentRadius); 
            
            for b = 1:3
                r = radii(b);
                [Xgrid, Ygrid] = meshgrid(-r:r, -r:r);
                circleMask = (Xgrid.^2 + Ygrid.^2) <= r^2;
                [oy, ox] = find(circleMask);
                brushes{b}.Y = oy - r - 1;
                brushes{b}.X = ox - r - 1;
            end
            
            % Paint the dots onto the canvas
            for i = 1:numStrokes
                y = randY(i);
                x = randX(i);
                    
                if i < (numStrokes * 0.4)
                    brushIdx = 1;
                elseif i < (numStrokes * 0.8)
                    brushIdx = 2;
                else
                    brushIdx = 3;
                end
                
                offsetY = brushes{brushIdx}.Y;
                offsetX = brushes{brushIdx}.X;
                
                rawCol = double(paintLayer(y, x, :));
                colorShift = double(randi([-30, 30], 1, 1, 3));
          
                col = uint8(max(0, min(255, rawCol + colorShift)));
                ly = y + offsetY;
                lx = x + offsetX;
                
                valid = lx >= 1 & lx <= cols & ly >= 1 & ly <= rows;
                lx = lx(valid); ly = ly(valid);
                
                % Apply the paint to the canvas
                % 1. Convert the 2D X/Y coordinates into a single 1D index
                idx = ly + (lx - 1) * rows;
                % 2. Calculate the offset for the Green and Blue color channels
                pageOffset = rows * cols;
                % 3. Dump the color onto all pixels simultaneously!
                canvas(idx) = col(1);
                canvas(idx + pageOffset) = col(2);
                canvas(idx + 2 * pageOffset) = col(3);
            end
            
            final_art = canvas;
            title(axComic, 'Pointillist Art');

        elseif strcmp(currentStyle, 'Stained Glass')
            app.SliderLabel.Text = '3. Shard Density:';
            val = thicknessSlider.Value;

            % 1. Get original dimensions
            [hOrig, wOrig, ~] = size(originalImg);
            
            % 2. Scale down image if pixels > 2^24, maxDim is 1000px for
            % the Voroonoi math to be fast
            maxDim = 1000; 
            if max(hOrig, wOrig) > maxDim
                scale = maxDim / max(hOrig, wOrig);
                h = round(hOrig * scale);
                w = round(wOrig * scale);
                paintLayerSmall = imresize(paintLayer, [h, w], 'nearest');
            else
                h = hOrig; w = wOrig;
                paintLayerSmall = paintLayer;
            end
            
            % 3. Scatter Seeds
            numSeeds = round(val * 500); 
            randY = randi([1, h], numSeeds, 1);
            randX = randi([1, w], numSeeds, 1);
            
            % 4. Calculate Voronoi map 
            binarySeeds = false(h, w);
            seedLinearIdx = sub2ind([h, w], randY, randX);
            binarySeeds(seedLinearIdx) = true;
            [~, neighborIdx] = bwdist(binarySeeds);
            
            % 5. Color the polygons
            glassSmall = zeros(h, w, 3, 'uint8');
            for chan = 1:3
                colorLayer = paintLayerSmall(:,:,chan);
                glassSmall(:,:,chan) = colorLayer(neighborIdx);
            end
            
            % 6. Resize back to original
            final_art = imresize(glassSmall, [hOrig, wOrig], 'nearest');
            
            % Shifts the shards slightly to create a physical "broken
            % glass" look
            shiftAmount = round(val * 0.25);
            if shiftAmount > 0
                final_art = circshift(final_art, [shiftAmount, -shiftAmount]);
            end

            % Detect edges on the color map itself
            grayGlass = rgb2gray(final_art);
            glassEdges = edge(grayGlass, 'sobel', 0.01);
            se = strel('disk', 1);
            thickEdges = imdilate(glassEdges, se);
            
            edgeMask = repmat(thickEdges, [1, 1, 3]);
            final_art(edgeMask) = 40; % Dark charcoal grout
            
            title(axComic, 'Voronoi Stained Glass');
    end
        
        imshow(final_art, 'Parent', axComic);
     end
end