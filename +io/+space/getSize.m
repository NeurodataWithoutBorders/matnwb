function [datasetSize, datasetMaxSize] = getSize(spaceId)
% getSize - Retrieves the current and maximum sizes of a dataset.
%
% Syntax:
%   [datasetSize, datasetMaxSize] = io.space.getSize(spaceId)
%
% Input Arguments:
%   spaceId {H5ML.id} - Identifier for the dataspace from which 
%   the dimensions are retrieved.
%
% Output Arguments:
%   datasetSize - Current size of the dataset dimensions.
%   datasetMaxSize - Maximum size of the dataset dimensions.
%
% Note:
%   - Flips dimensions as the h5 function returns dimensions in C-style order
%     whereas MATLAB represents data in F-style order
%   - Replaces H5 constants with Inf for unlimited dimensions

    arguments
        spaceId {matnwb.common.compatibility.mustBeA(spaceId, "H5ML.id")}
    end

    [~, h5Dims, h5MaxDims] = H5S.get_simple_extent_dims(spaceId);
    datasetSize = fliplr(h5Dims);
    datasetMaxSize = fliplr(h5MaxDims);

    h5Unlimited = H5ML.get_constant_value('H5S_UNLIMITED');
    datasetMaxSize(datasetMaxSize == h5Unlimited) = Inf;
end
