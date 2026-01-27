classdef ZarrBackend < io.backend.FileBackend
    % ZarrBackend - Zarr implementation of FileBackend
    %
    % This class provides Zarr-specific implementations for reading NWB files
    % stored in Zarr format. It uses Python's zarr library through MATLAB's
    % Python interface.
    
    properties (Access = protected)
        filename
        fileId % Will store the zarr group object
        zarrModule
        jsonModule
    end
    
    methods
        function obj = ZarrBackend(filename)
            arguments
                filename (1,1) string
            end
            obj@io.backend.FileBackend(filename);
            obj.filename = char(filename);
            
            % Initialize Python modules
            try
                obj.zarrModule = py.importlib.import_module('zarr');
                obj.jsonModule = py.importlib.import_module('json');
            catch ME
                error('NWB:ZarrBackend:PythonNotAvailable', ...
                    'Python zarr module not available. Install with: pip install zarr');
            end
        end
        
        function open(obj)
            if ~obj.isFileOpen()
                try
                    obj.fileId = obj.zarrModule.open(obj.filename, mode='r');
                catch ME
                    error('NWB:ZarrBackend:OpenFailed', ...
                        'Failed to open Zarr file: %s', ME.message);
                end
            end
        end
        
        function close(obj)
            if obj.isFileOpen()
                obj.fileId = [];
            end
        end
        
        function isOpen = isFileOpen(obj)
            isOpen = ~isempty(obj.fileId);
        end
        
        function groupInfo = getGroupInfo(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            obj.open();
            try
                if path == "/"
                    zarrGroup = obj.fileId;
                else
                    zarrGroup = obj.fileId{char(path)};
                end
                
                % Convert Zarr group to h5info-like structure
                groupInfo = obj.zarrGroupToInfo(zarrGroup, char(path));
            catch
                groupInfo = [];
            end
        end
        
        function groupExists = hasGroup(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            obj.open();
            try
                if path == "/"
                    groupExists = true;
                else
                    group = obj.fileId{char(path)};
                    groupExists = ~isempty(group);
                end
            catch
                groupExists = false;
            end
        end
        
        function datasetInfo = getDatasetInfo(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            obj.open();
            try
                dataset = obj.fileId{char(path)};
                datasetInfo = obj.zarrArrayToInfo(dataset, char(path));
            catch
                datasetInfo = [];
            end
        end
        
        function data = readDataset(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            obj.open();
            try
                dataset = obj.fileId{char(path)};
                data = double(dataset{':'});  % Read all data and convert to MATLAB
            catch ME
                error('NWB:ZarrBackend:ReadFailed', ...
                    'Failed to read dataset %s: %s', path, ME.message);
            end
        end
        
        function datasetExists = hasDataset(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            obj.open();
            try
                dataset = obj.fileId{char(path)};
                % Check if it's an array (dataset) rather than a group
                datasetExists = isa(dataset, 'py.zarr.core.Array');
            catch
                datasetExists = false;
            end
        end
        
        function attributes = getAttributes(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            obj.open();
            try
                if path == "/"
                    zarrObj = obj.fileId;
                else
                    zarrObj = obj.fileId{char(path)};
                end
                
                % Convert Zarr attributes to h5info-like structure
                attributes = obj.zarrAttrsToInfo(zarrObj.attrs);
            catch
                attributes = [];
            end
        end
        
        function attributeValue = readAttribute(obj, path, attributeName)
            arguments
                obj
                path (1,1) string
                attributeName (1,1) string
            end
            
            obj.open();
            try
                if path == "/"
                    zarrObj = obj.fileId;
                else
                    zarrObj = obj.fileId{char(path)};
                end
                
                attributeValue = zarrObj.attrs{char(attributeName)};
                attributeValue = obj.pythonToMatlab(attributeValue);
            catch
                attributeValue = [];
            end
        end
        
        function attributeExists = hasAttribute(obj, path, attributeName)
            arguments
                obj
                path (1,1) string
                attributeName (1,1) string
            end
            
            obj.open();
            try
                if path == "/"
                    zarrObj = obj.fileId;
                else
                    zarrObj = obj.fileId{char(path)};
                end
                
                attributeExists = zarrObj.attrs.contains(char(attributeName));
            catch
                attributeExists = false;
            end
        end
        
        function datatype = getDatatype(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            obj.open();
            dataset = obj.fileId{char(path)};
            % Return a structure mimicking HDF5 datatype info
            datatype = struct();
            datatype.Class = char(dataset.dtype);
            datatype.Type = char(dataset.dtype);
        end
        
        function matType = getMatType(obj, datatype)
            arguments
                obj
                datatype
            end
            
            % Map Zarr/NumPy dtypes to MATLAB types
            switch datatype.Class
                case {'float64', '<f8', '>f8'}
                    matType = 'double';
                case {'float32', '<f4', '>f4'}
                    matType = 'single';
                case {'int64', '<i8', '>i8'}
                    matType = 'int64';
                case {'int32', '<i4', '>i4'}
                    matType = 'int32';
                case {'int16', '<i2', '>i2'}
                    matType = 'int16';
                case {'int8', '<i1', '>i1'}
                    matType = 'int8';
                case {'uint64', '<u8', '>u8'}
                    matType = 'uint64';
                case {'uint32', '<u4', '>u4'}
                    matType = 'uint32';
                case {'uint16', '<u2', '>u2'}
                    matType = 'uint16';
                case {'uint8', '<u1', '>u1'}
                    matType = 'uint8';
                case {'bool'}
                    matType = 'logical';
                case {'U', 'S'} % Unicode or byte strings
                    matType = 'char';
                otherwise
                    matType = 'double'; % Default fallback
            end
        end
        
        function referenceData = parseReference(obj, datasetId, typeId, data)
            arguments
                obj
                datasetId
                typeId
                data
            end
            
            % Zarr doesn't have native references like HDF5
            % This would need to be implemented based on how references
            % are stored in Zarr-based NWB files
            warning('NWB:ZarrBackend:ReferencesNotImplemented', ...
                'Reference parsing not yet implemented for Zarr backend');
            referenceData = data;
        end
        
        function pathExists = exists(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            obj.open();
            try
                if path == "/"
                    pathExists = true;
                else
                    obj.fileId{char(path)};
                    pathExists = true;
                end
            catch
                pathExists = false;
            end
        end
        
        function pathType = getPathType(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            obj.open();
            try
                if path == "/"
                    pathType = 'group';
                else
                    zarrObj = obj.fileId{char(path)};
                    if isa(zarrObj, 'py.zarr.core.Array')
                        pathType = 'dataset';
                    else
                        pathType = 'group';
                    end
                end
            catch
                pathType = '';
            end
        end
    end
    
    methods (Access = private)
        function info = zarrGroupToInfo(obj, zarrGroup, path)
            % Convert Zarr group to h5info-like structure
            info = struct();
            info.Name = path;
            info.Groups = [];
            info.Datasets = [];
            info.Attributes = obj.zarrAttrsToInfo(zarrGroup.attrs);
            info.Links = [];
            
            % Get group members
            try
                keys = cell(zarrGroup.keys());
                for i = 1:length(keys)
                    key = keys{i};
                    member = zarrGroup{key};
                    if isa(member, 'py.zarr.core.Array')
                        % It's a dataset
                        datasetInfo = obj.zarrArrayToInfo(member, [path '/' key]);
                        info.Datasets = [info.Datasets; datasetInfo];
                    else
                        % It's a group
                        groupInfo = struct();
                        groupInfo.Name = [path '/' key];
                        info.Groups = [info.Groups; groupInfo];
                    end
                end
            catch
                % Handle case where keys() fails
            end
        end
        
        function info = zarrArrayToInfo(obj, zarrArray, path)
            % Convert Zarr array to h5info dataset-like structure
            info = struct();
            info.Name = path;
            info.Datatype = struct();
            info.Datatype.Class = char(zarrArray.dtype);
            info.Datatype.Type = char(zarrArray.dtype);
            info.Dataspace = struct();
            info.Dataspace.Type = 'simple';
            info.Dataspace.Size = double(zarrArray.shape);
            info.Attributes = obj.zarrAttrsToInfo(zarrArray.attrs);
        end
        
        function attributes = zarrAttrsToInfo(obj, zarrAttrs)
            % Convert Zarr attributes to h5info-like structure
            attributes = [];
            try
                keys = cell(zarrAttrs.keys());
                for i = 1:length(keys)
                    key = keys{i};
                    value = zarrAttrs{key};
                    
                    attr = struct();
                    attr.Name = key;
                    attr.Value = obj.pythonToMatlab(value);
                    attr.Datatype = struct();
                    attr.Datatype.Class = 'H5T_STRING'; % Default for now
                    
                    attributes = [attributes; attr];
                end
            catch
                % Handle case where attributes access fails
            end
        end
        
        function matlabValue = pythonToMatlab(obj, pythonValue)
            % Convert Python values to MATLAB equivalents
            if isa(pythonValue, 'py.str')
                matlabValue = char(pythonValue);
            elseif isa(pythonValue, 'py.list')
                matlabValue = cell(pythonValue);
            elseif isa(pythonValue, 'py.numpy.ndarray')
                matlabValue = double(pythonValue);
            else
                try
                    matlabValue = double(pythonValue);
                catch
                    matlabValue = char(pythonValue);
                end
            end
        end
    end
end
