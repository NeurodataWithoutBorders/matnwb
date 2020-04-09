classdef Bound < types.untyped.datapipe.Pipe
    %BOUND Represents a Bound DataPipe which must point to a valid file.
    
    properties (SetAccess = private)
        filename; % OS path to the HDF5 file.
        path; % HDF5 path to the chunked dataset.
    end
    
    methods
        function obj = Bound(filename, path)
        end
    end
end