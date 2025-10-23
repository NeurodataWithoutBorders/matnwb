function planeSegmentation = PlaneSegmentation(imagingPlane, options)
% PlaneSegmentation - Create a PlaneSegmentation object with default values
%
% Usage:
%   planeSegmentation = tests.factory.PlaneSegmentation(imagingPlane)
%   planeSegmentation = tests.factory.PlaneSegmentation(imagingPlane, 'roi_type', 'image_mask')
%
% Input:
%   imagingPlane - ImagingPlane object
%   options - Name-value pairs:
%     'RoiType' - 'image_mask' (default) or 'pixel_mask'
%     'NumRois' - Number of ROIs to create (default: 20)
%     'ImageShape' - [height, width] of imaging plane (default: [100, 100])
%
% Output:
%   planeSegmentation - PlaneSegmentation object

    arguments
        imagingPlane (1,1) types.core.ImagingPlane = tests.factory.ImagingPlane
        options.RoiType (1,1) string ...
            {mustBeMember(options.RoiType, ["image_mask", "pixel_mask"])} = 'image_mask'
        options.NumRois (1,1) double = 20
        options.ImageShape (1,2) double = [100, 100]
    end

    roiType = options.RoiType;
    nRois = options.NumRois;
    imageShape = options.ImageShape;
    
    % Generate fake image_mask data
    y = imageShape(1);
    x = imageShape(2);
    
    image_mask = zeros(y, x, nRois);
    center = randi(90, 2, nRois);
    for i = 1:nRois
        % Create a small square ROI (10x10 pixels)
        row_start = max(1, center(1,i));
        row_end = min(y, row_start + 10);
        col_start = max(1, center(2,i));
        col_end = min(x, col_start + 10);
        
        image_mask(row_start:row_end, col_start:col_end, i) = 1;
    end
    
    if strcmp(roiType, 'pixel_mask')
        % Convert image_mask to pixel_mask
        ind = find(image_mask);
        [y_ind, x_ind, roi_ind] = ind2sub(size(image_mask), ind);
        
        pixel_mask_struct = struct();
        pixel_mask_struct.x = uint32(x_ind);
        pixel_mask_struct.y = uint32(y_ind);
        pixel_mask_struct.weight = single(ones(size(x_ind)));
        
        % Create pixel mask vector data
        pixel_mask = types.hdmf_common.VectorData(...
            'data', struct2table(pixel_mask_struct), ...
            'description', 'pixel masks');
        
        % Create pixel_mask_index vector
        num_pixels_per_roi = zeros(nRois, 1);
        for i_roi = 1:nRois
            num_pixels_per_roi(i_roi) = sum(roi_ind == i_roi);
        end
        
        pixel_mask_index_data = uint16(cumsum(num_pixels_per_roi));
        
        pixel_mask_index = types.hdmf_common.VectorIndex(...
            'description', 'Index into pixel_mask VectorData', ...
            'data', pixel_mask_index_data, ...
            'target', types.untyped.ObjectView(pixel_mask));
        
        planeSegmentation = types.core.PlaneSegmentation( ...
            'colnames', {'pixel_mask'}, ...
            'description', 'ROI pixel position (x,y) and pixel weight', ...
            'imaging_plane', types.untyped.SoftLink(imagingPlane), ...
            'pixel_mask_index', pixel_mask_index, ...
            'pixel_mask', pixel_mask ...
        );
    else % image_mask
        planeSegmentation = types.core.PlaneSegmentation( ...
            'colnames', {'image_mask'}, ...
            'description', 'Output from segmenting imaging plane', ...
            'imaging_plane', types.untyped.SoftLink(imagingPlane), ...
            'image_mask', types.hdmf_common.VectorData(...
                'data', image_mask, ...
                'description', 'image masks') ...
        );
    end
end
