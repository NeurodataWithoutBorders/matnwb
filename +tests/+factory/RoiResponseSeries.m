function roiResponseSeries = RoiResponseSeries(planeSegmentation, options)
% RoiResponseSeries - Create a RoiResponseSeries object with default values
%
% Usage:
%   roiResponseSeries = tests.factory.RoiResponseSeries(planeSegmentation)
%   roiResponseSeries = tests.factory.RoiResponseSeries(planeSegmentation, 'NumTimepoints', 100)
%
% Input:
%   planeSegmentation - PlaneSegmentation object
%   options - Name-value pairs:
%     'NumTimepoints' - Number of timepoints (default: 100)
%     'SamplingRate' - Sampling rate (default: 30)
%
% Output:
%   roiResponseSeries - RoiResponseSeries object

    arguments
        planeSegmentation (1,1) types.core.PlaneSegmentation = tests.factory.PlaneSegmentation
        options.NumTimepoints (1,1) double = 100
        options.SamplingRate (1,1) double = 30
    end
    
    numTimepoints = options.NumTimepoints;
    startingTime = 0;
    startingTimeRate = options.SamplingRate;
    
    % Get the number of ROIs from the planeSegmentation
    if ~isempty(planeSegmentation.image_mask)
        n_rois = size(planeSegmentation.image_mask.data, 3);
    elseif ~isempty(planeSegmentation.pixel_mask_index)
        n_rois = length(planeSegmentation.pixel_mask_index.data);
    else
        n_rois = 20; % Default if we can't determine from planeSegmentation
    end
    
    % Create a DynamicTableRegion that references all ROIs
    roi_table_region = types.hdmf_common.DynamicTableRegion( ...
        'table', types.untyped.ObjectView(planeSegmentation), ...
        'description', 'all_rois', ...
        'data', (0:n_rois-1)');
    
    % Generate random fluorescence data
    % In MatNWB, time should be along the last dimension [nRoi, nT]
    data = rand(n_rois, numTimepoints);
    
    % Create the RoiResponseSeries
    roiResponseSeries = types.core.RoiResponseSeries( ...
        'rois', roi_table_region, ...
        'data', data, ...
        'data_unit', 'lumens', ...
        'starting_time_rate', startingTimeRate, ...
        'starting_time', startingTime);
end
