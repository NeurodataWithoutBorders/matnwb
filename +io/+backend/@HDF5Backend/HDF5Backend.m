classdef HDF5Backend < io.backend.FileBackend
    % HDF5Backend - HDF5 implementation of FileBackend
    %
    % This class provides HDF5-specific implementations for reading NWB files
    % stored in HDF5 format, wrapping the existing HDF5 functionality.
    
    properties (Access = protected)
        filename
        fileId
    end
    
    methods
        function obj = HDF5Backend(filename)
            arguments
                filename (1,1) string
            end
            obj@io.backend.FileBackend(filename);
            obj.Filename = char(filename);
            obj.open()
        end

        function delete(obj)
            obj.close()
            disp('Closed file')
        end
    end

    methods
        
        %% File-level methods
        
        function open(obj)
            if ~obj.isFileOpen()
                obj.fileId = H5F.open(obj.Filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
            end
        end
        
        function close(obj)
            if obj.isFileOpen()
                H5F.close(obj.fileId);
                obj.fileId = H5ML.id();
            end
        end
        
        function info = getFileInfo(obj)
            info = obj.getGroupInfo('/');
        end

        function version = getSchemaVersion(obj)
            version =  util.getSchemaVersion(obj.Filename);
        end

        function specLocation = getEmbeddedSpecLocation(obj)
            specLocation = io.spec.getEmbeddedSpecLocation(obj.Filename);
        end

        function isOpen = isFileOpen(obj)
            isOpen = ~isempty(obj.fileId) && H5I.is_valid(obj.fileId);
        end
        
        %% Methods to handle groups
        
        function groupInfo = getGroupInfo(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            % Use h5info to get group information
            try
                if path == "/"
                    groupInfo = h5info(obj.Filename);
                else
                    groupInfo = h5info(obj.Filename, char(path));
                end
            catch ME
                if contains(ME.message, 'not found')
                    groupInfo = [];
                else
                    rethrow(ME);
                end
            end
        end
        
        function groupExists = hasGroup(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            try
                obj.open();
                gid = H5G.open(obj.fileId, char(path), 'H5P_DEFAULT');
                H5G.close(gid);
                groupExists = true;
            catch
                groupExists = false;
            end
        end
        
        %% Methods to handle datasets
        
        function datasetInfo = getDatasetInfo(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            try
                datasetInfo = h5info(obj.Filename, char(path));
            catch ME
                if contains(ME.message, 'not found')
                    datasetInfo = [];
                else
                    rethrow(ME);
                end
            end
        end
        
        function data = readDataset(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            obj.open();
            did = H5D.open(obj.fileId, char(path));
            data = H5D.read(did);
            H5D.close(did);
        end
        
        datasetValue = processDatasetInfo(obj, datasetInfo, datasetPath)

        function datasetExists = hasDataset(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            try
                obj.open();
                did = H5D.open(obj.fileId, char(path), 'H5P_DEFAULT');
                H5D.close(did);
                datasetExists = true;
            catch
                datasetExists = false;
            end
        end
        
        %% Methods to handle attributes
        
        function attributes = getAttributes(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            try
                info = h5info(obj.Filename, char(path));
                attributes = info.Attributes;
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
            
            try
                attributeValue = h5readatt(obj.Filename, char(path), char(attributeName));
            catch ME
                if contains(ME.message, 'not found')
                    attributeValue = [];
                else
                    rethrow(ME);
                end
            end
        end
        
        attributeValue = processAttributeInfo(obj, attributeInfo, attributePath) % Function in separate file

        function attributeExists = hasAttribute(obj, path, attributeName)
            arguments
                obj
                path (1,1) string
                attributeName (1,1) string
            end
            
            try
                h5readatt(obj.Filename, char(path), char(attributeName));
                attributeExists = true;
            catch
                attributeExists = false;
            end
        end
        
        %% Utility methods
        
        function datatype = getDatatype(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            obj.open();
            did = H5D.open(obj.fileId, char(path));
            tid = H5D.get_type(did);
            datatype = tid; % Return the type ID for HDF5
            H5D.close(did);
        end
        
        function matType = getMatType(obj, datatype)
            arguments
                obj
                datatype
            end
            
            matType = io.getMatType(datatype);
        end
        
        function referenceData = parseReference(obj, datasetId, typeId, data)
            arguments
                obj
                datasetId
                typeId
                data
            end
            
            referenceData = io.parseReference(datasetId, typeId, data);
        end
        
        function pathExists = exists(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            try
                h5info(obj.Filename, char(path));
                pathExists = true;
            catch
                pathExists = false;
            end
        end
        
        function pathType = getPathType(obj, path)
            arguments
                obj
                path (1,1) string
            end
            
            try
                info = h5info(obj.Filename, char(path));
                if isfield(info, 'Groups') || isfield(info, 'Datasets')
                    pathType = 'group';
                else
                    pathType = 'dataset';
                end
            catch
                pathType = '';
            end
        end
    end
end
