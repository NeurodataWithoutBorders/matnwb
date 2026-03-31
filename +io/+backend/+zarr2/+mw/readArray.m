function data = readArray(filepath)
% readArray - Read a Zarr array through the MathWorks wrapper.

    io.backend.zarr2.mw.ensureAvailable()
    try
        data = zarrread(char(filepath));
    catch ME
        if strcmp(ME.identifier, 'MATLAB:Python:PyException') ...
                && contains(ME.message, 'tensorstore')
            error("NWB:Zarr2:TensorStoreMissing", ...
                "The MathWorks Zarr wrapper requires the python package `tensorstore` to be installed in the active MATLAB python environment.")
        else
            rethrow(ME)
        end
    end
end
