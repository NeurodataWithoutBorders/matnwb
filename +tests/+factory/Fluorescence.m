function fluorescence = Fluorescence(roiResponseSeries, options)
% Fluorescence - Create a Fluorescence object with default values
%
% Usage:
%   fluorescence = tests.factory.Fluorescence(roiResponseSeries, options)
%
% Input:
%   roiResponseSeries - RoiResponseSeries object
%   options - Name-value pairs:
%     'Name' - Name to use for neurodata type (default: "RoiResponseSeries")
%
% Output:
%   fluorescence - Fluorescence object

    arguments
        roiResponseSeries (1,1) types.core.RoiResponseSeries = tests.factory.RoiResponseSeries
        options.Name (1,1) string = "RoiResponseSeries"
    end
    
    % Create the Fluorescence container
    fluorescence = types.core.Fluorescence();
    
    % Add the RoiResponseSeries to the Fluorescence container
    fluorescence.add(options.Name, roiResponseSeries);
end
