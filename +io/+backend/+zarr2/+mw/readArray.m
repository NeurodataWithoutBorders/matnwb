function data = readArray(filepath, start, count, stride)
% readArray - Read a Zarr array through the MathWorks wrapper.

    if nargin < 2
        start = [];
        count = [];
        stride = [];
    end

    io.backend.zarr2.mw.ensureAvailable()
    try
        if isempty(start) && isempty(count) && isempty(stride)
            data = zarrread(char(filepath));
        else
            data = zarrread(char(filepath), ...
                Start=start, Count=count, Stride=stride);
        end
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
