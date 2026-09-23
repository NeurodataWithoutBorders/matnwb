function datasetValue = normalizeDatasetDimensions(datasetValue, rank)
% normalizeDatasetDimensions - Reverse axis order for rank >= 2 data.
%
% Reverses all axes of datasetValue when rank is >= 2. rank is the array's
% Zarr rank, i.e. numel(shape) as reported by zarr-matlab -- NOT MATLAB's
% ndims, which cannot distinguish a genuine rank-1 column vector from a
% rank-2 array.
%
% Zarr v3 stores written by Python NWB tools use numpy/row-major shape order
% (matching the NWB schema's declared shape directly). MatNWB's type system
% (types.util.validateShape, checkDims) expects the reverse of that for rank
% >= 2, matching the convention already used by io.backend.hdf5.HDF5Reader.
%
% A rank-1 Zarr array is already read by zarr-matlab as a MATLAB column
% vector (see zarr.internal.mshape), so it is left untouched here.

    if rank < 2
        return
    end

    if rank == 2
        datasetValue = datasetValue.';
    else
        datasetValue = permute(datasetValue, rank:-1:1);
    end
end
