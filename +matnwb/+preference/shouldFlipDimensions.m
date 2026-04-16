function shouldFlip = shouldFlipDimensions()
%SHOULDFLIPDIMENSIONS Return true if dimensions should be flipped at HDF5 boundary.
%
%   shouldFlip = matnwb.preference.shouldFlipDimensions() returns true when
%   the active dimension ordering mode is matlab_style (legacy behavior that
%   reverses dimensions so MATLAB users work in F-order) and false when the
%   mode is schema_style (no reversal; dimensions match HDF5/NWB schema order).
%
%   This is the low-overhead query function used at every read/write boundary
%   inside matnwb. The result is cached after the first call.
%
%   See also:
%     matnwb.preference.DimensionOrder
%     matnwb.preference.DimensionOrderMode
    shouldFlip = matnwb.preference.DimensionOrder.shouldFlipDimensions();
end
