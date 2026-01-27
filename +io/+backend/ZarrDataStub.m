classdef ZarrDataStub < handle
    % ZarrDataStub - Lazy loading stub for Zarr datasets
    %
    % This class provides lazy loading functionality for Zarr datasets,
    % similar to types.untyped.DataStub for HDF5 files.
    
    properties (SetAccess = private)
        filename
        path
        backend
    end
    
    methods
        function obj = ZarrDataStub(filename, path)
            arguments
                filename (1,1) string
                path (1,1) string
            end
            
            obj.filename = filename;
            obj.path = path;
            obj.backend = io.backend.ZarrBackend(filename);
        end
        
        function data = load(obj)
            % Load the actual data from the Zarr file
            data = obj.backend.readDataset(obj.path);
        end
        
        function info = getDatasetInfo(obj)
            % Get information about the dataset without loading data
            info = obj.backend.getDatasetInfo(obj.path);
        end
        
        function tf = isLoaded(obj)
            % Check if data is loaded (always false for stubs)
            tf = false;
        end
    end
end
