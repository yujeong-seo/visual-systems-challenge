% Function to upload the image in UI modal

function upload_image(ax_input, btn_process, lbl_filename, fig)

    [file, path] = uigetfile({'*.jpg;*.jpeg;*.png;', 'Image Files'});
    if isequal(file, 0)
        return; end

    I = imread(fullfile(path, file));
    setappdata(fig, 'I_loaded', I);
    imshow(I, 'Parent', ax_input);

    lbl_filename.Text      = file;
    lbl_filename.FontAngle = 'normal';
    btn_process.Enable     = 'on';
end
