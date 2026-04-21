function attributes = readAttributes(filepath)
% readAttributes - Read .zattrs through the MathWorks wrapper.

    io.backend.zarr2.mw.ensureAvailable()
    attributes = readZattrs(char(filepath));
end
