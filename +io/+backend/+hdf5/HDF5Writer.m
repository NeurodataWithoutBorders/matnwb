classdef HDF5Writer < io.backend.base.Writer
    % HDF5Writer - HDF5 implementation of the backend writer interface.
    %
    % This writer is intentionally thin and delegates to the existing HDF5
    % utility functions used by matnwb today.

    methods
        function obj = HDF5Writer(fileId)
            obj@io.backend.base.Writer(fileId);
        end

        function groupExists = writeGroup(obj, groupPath)
            groupExists = io.writeGroup(obj.fileId, groupPath);
        end

        function writeValue(obj, datasetPath, value, varargin)
            if istable(value) || isstruct(value) || isa(value, "containers.Map")
                io.writeCompound(obj.fileId, datasetPath, value, varargin{:});
            else
                io.writeDataset(obj.fileId, datasetPath, value, varargin{:});
            end
        end

        function writeAttribute(obj, attributePath, value, varargin)
            io.writeAttribute(obj.fileId, attributePath, value, varargin{:});
        end
    end
end
