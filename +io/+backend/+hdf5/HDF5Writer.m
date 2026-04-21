classdef HDF5Writer < io.backend.base.Writer
    % HDF5Writer - HDF5 implementation of the backend writer interface.
    %
    % This writer is intentionally thin and delegates to the existing HDF5
    % utility functions used by matnwb today.

    properties (SetAccess = private, Hidden)
        H5FileId
    end

    properties
        % Flag used to clean up if something goes wrong.
        IsEditingFile (1,1) logical = false
        OwnsFileHandle (1,1) logical = true
    end

    methods
        function obj = HDF5Writer(fileReference, mode)
            arguments
                fileReference
                mode (1,1) string {mustBeMember(mode, ["edit", "overwrite"])} = "edit"
            end
            if isa(fileReference, 'H5ML.id')
                filename = string(H5F.get_name(fileReference));
            else
                filename = string(fileReference);
            end

            obj@io.backend.base.Writer(filename);

            if isa(fileReference, 'H5ML.id')
                obj.H5FileId = fileReference;
                obj.OwnsFileHandle = false;
            else
                if isfile(obj.Filename)
                    if mode == "edit"
                        obj.H5FileId = H5F.open(filename, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
                        obj.IsEditingFile = true;
                    elseif mode == "overwrite"
                        obj.H5FileId = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
                    end
                else
                    obj.H5FileId = H5F.create(filename);
                end
            end
        end
    
        function delete(obj)
            obj.close();
        end
    end
    
    methods
        function close(obj)
            if obj.OwnsFileHandle && ~isempty(obj.H5FileId) && isvalid(obj.H5FileId)
                H5F.close(obj.H5FileId);
            end
            obj.H5FileId = [];
        end

        function abort(obj)
            filePath = char(obj.Filename);
            shouldDeleteFile = obj.OwnsFileHandle && ~obj.IsEditingFile && isfile(filePath);
            obj.close();
            if shouldDeleteFile
                delete(filePath);
            end
        end

        function groupExists = writeGroup(obj, groupPath)
            groupExists = io.writeGroup(obj.H5FileId, groupPath);
        end

        function writeValue(obj, datasetPath, value, varargin)
            if istable(value) || isstruct(value) || isa(value, "containers.Map")
                io.writeCompound(obj.H5FileId, datasetPath, value, varargin{:});
            else
                io.writeDataset(obj.H5FileId, datasetPath, value, varargin{:});
            end
        end

        function writeAttribute(obj, attributePath, value, varargin)
            io.writeAttribute(obj.H5FileId, attributePath, value, varargin{:});
        end
    end

    methods (Access = protected)
        function fileId = getFileId(obj)
            fileId = obj.H5FileId;
        end
    end
end
