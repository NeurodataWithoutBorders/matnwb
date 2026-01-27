classdef ZarrDataPipe < handle
    % ZarrDataPipe - Chunked data access for Zarr datasets
    %
    % This class provides chunked data access functionality for Zarr datasets,
    % similar to types.untyped.DataPipe for HDF5 files.
    
    properties (SetAccess = private)
        filename
        path
        backend
        datasetInfo
    end
    
    methods
        function obj = ZarrDataPipe(filename, path)
            arguments
                filename (1,1) string
                path (1,1) string
            end
            
            obj.filename = filename;
            obj.path = path;
            obj.backend = io.backend.ZarrBackend(filename);
            obj.datasetInfo = obj.backend.getDatasetInfo(path);
        end
        
        function data = load(obj, varargin)
            % Load data with optional indexing
            % Usage: load(obj) - load all data
            %        load(obj, indices) - load specific indices
            
            if isempty(varargin)
                % Load all data
                data = obj.backend.readDataset(obj.path);
            else
                % Load specific indices (would need implementation in ZarrBackend)
                indices = varargin{1};
                warning('NWB:ZarrDataPipe:IndexingNotImplemented', ...
                    'Indexed loading not yet implemented for Zarr. Loading all data.');
                data = obj.backend.readDataset(obj.path);
            end
        end
        
        function dims = getDimensions(obj)
            % Get dataset dimensions
            if ~isempty(obj.datasetInfo) && isfield(obj.datasetInfo, 'Dataspace')
                dims = obj.datasetInfo.Dataspace.Size;
            else
                dims = [];
            end
        end
        
        function dtype = getDataType(obj)
            % Get dataset data type
            if ~isempty(obj.datasetInfo) && isfield(obj.datasetInfo, 'Datatype')
                dtype = obj.datasetInfo.Datatype.Class;
            else
                dtype = '';
            end
        end
        
        function tf = isChunked(obj)
            % Check if dataset is chunked (always true for Zarr)
            tf = true;
        end
    end
end
