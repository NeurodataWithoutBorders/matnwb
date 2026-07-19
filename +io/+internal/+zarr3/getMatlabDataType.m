function matlabDataType = getMatlabDataType(zarrDataType)
% getMatlabDataType - Map a Zarr v3 data_type name to a MATLAB class name.
%
%   matlabDataType = getMatlabDataType(zarrDataType) resolves the MATLAB
%   class used to represent values of the given Zarr v3 `data_type` (e.g.
%   "float64", "int64", "bool", "string"), reusing the dtype table from the
%   zarr-matlab package.

    info = zarr.internal.dtype_info(zarrDataType);
    matlabDataType = char(info.matlabClass);
end
