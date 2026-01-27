classdef (Abstract) FileBackend < handle
    % FileBackend - Abstract base class for file format backends
    %
    % This class defines the interface that all file format backends must
    % implement to support reading NWB files from different storage formats
    % (HDF5, Zarr, etc.).
    
    properties (Access = protected)
        Filename
        FileID
    end
    
    methods (Abstract)
        % File operations
        open(obj)
        close(obj)
        isOpen = isFileOpen(obj)
        info = getFileInfo(obj)
        ver = getSchemaVersion(obj)
        
        % Group operations
        groupInfo = getGroupInfo(obj, path)
        groupExists = hasGroup(obj, path)
        
        % Dataset operations
        datasetInfo = getDatasetInfo(obj, path)
        data = readDataset(obj, path)
        datasetExists = hasDataset(obj, path)
              
        datasetValue = processDatasetInfo(obj, info, datasetPath)

        % Attribute operations
        attributes = getAttributes(obj, path)
        attributeValue = readAttribute(obj, path, attributeName)
        attributeExists = hasAttribute(obj, path, attributeName)
        attributeValue = processAttributeInfo(obj, info, attributePath)
        
        % Type operations
        datatype = getDatatype(obj, path)
        matType = getMatType(obj, datatype)
        
        % Reference operations (for HDF5 compatibility)
        referenceData = parseReference(obj, datasetId, typeId, data)
        
        % Utility operations
        pathExists = exists(obj, path)
        pathType = getPathType(obj, path) % 'group', 'dataset', or 'link'
    end
    
    methods
        function obj = FileBackend(filename)
            arguments
                filename (1,1) string
            end
            obj.Filename = filename;
        end
        
        function delete(obj)
            if obj.isFileOpen()
                obj.close();
            end
        end
    end
end
