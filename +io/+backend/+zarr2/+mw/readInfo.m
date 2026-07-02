function info = readInfo(filepath)
% readInfo - Read .zgroup/.zarray metadata through the MathWorks wrapper.

    io.backend.zarr2.mw.ensureAvailable()
    info = zarrinfo(char(filepath));
end
