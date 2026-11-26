classdef HDF5LazyArray < io.backend.base.LazyArray
% HDF5LazyArray - HDF5-backed lazy dataset access implementation.
%
% MATLAB's HDF5 functions present a dataset in MATLAB's dimension order,
% which is MatNWB's, so the storage order is not reversed. A point
% selection is cheap in HDF5, so a linear selection is read through its
% bounding box only when it fills the box (the base class default).

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
            fileId = H5F.open(obj.Filename);
            datasetId = H5D.open(fileId, obj.DatasetPath);
            typeId = H5D.get_type(datasetId);

            dataType = io.getMatType(typeId);

            H5T.close(typeId);
            H5D.close(datasetId);
            H5F.close(fileId);
        end

        data = load_h5_style(obj, varargin)
    end

    methods (Access = protected)
        data = readSubscripts(obj, selection)

        values = readPoints(obj, subscripts)
    end

    methods (Access = private)
        function spaceId = getSpace(obj)
            fileId = H5F.open(obj.Filename);
            datasetId = H5D.open(fileId, obj.DatasetPath);
            spaceId = H5D.get_space(datasetId);
            H5D.close(datasetId);
            H5F.close(fileId);
        end
    end
end
