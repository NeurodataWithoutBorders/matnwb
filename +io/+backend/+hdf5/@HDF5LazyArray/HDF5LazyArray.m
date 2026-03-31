classdef HDF5LazyArray < io.backend.base.LazyArray
% HDF5LazyArray - HDF5-backed lazy dataset access implementation.

    methods
        function obj = HDF5LazyArray(filename, path, dims, dataType)
            arguments
                filename (1,1) string
                path (1,1) string
                dims double = []
                dataType = []
            end
            obj@io.backend.base.LazyArray(filename, path, dims, dataType);
        end

        function refreshSizeInfo(obj)
            spaceId = obj.getSpace();
            [dims, maxDims] = io.space.getSize(spaceId);
            H5S.close(spaceId);
            obj.setSizeInfo(dims, maxDims);
        end

        function dataType = resolveDataType(obj)
            fileId = H5F.open(obj.filename);
            datasetId = H5D.open(fileId, obj.path);
            typeId = H5D.get_type(datasetId);

            dataType = io.getMatType(typeId);

            H5T.close(typeId);
            H5D.close(datasetId);
            H5F.close(fileId);
        end
    
        data = load_h5_style(obj, varargin)

        data = load_mat_style(obj, varargin)
    end

    methods (Access = private)
        function spaceId = getSpace(obj)
            fileId = H5F.open(obj.filename);
            datasetId = H5D.open(fileId, obj.path);
            spaceId = H5D.get_space(datasetId);
            H5D.close(datasetId);
            H5F.close(fileId);
        end
    end
end

