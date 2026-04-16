classdef DimensionOrderMode
%DIMENSIONORDERMODE Enumeration of supported dimension ordering modes.
%
%   Values:
%     matlab_style  - Legacy behavior. Dimensions are flipped at the HDF5
%                     boundary so that MATLAB users see column-major (F-order)
%                     indexing. The fastest-changing dimension is first.
%                     This is the default for backward compatibility.
%
%     schema_style  - Schema-consistent behavior. Dimensions are NOT flipped.
%                     Arrays are indexed in the same order as in the NWB schema
%                     and HDF5 files (C-order, slowest-changing dimension first).

    enumeration
        matlab_style
        schema_style
    end
end
