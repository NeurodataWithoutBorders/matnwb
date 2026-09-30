classdef HDF5LazyArraySpy < io.backend.hdf5.HDF5LazyArray
% HDF5LazyArraySpy - Test spy that counts reads from an HDF5 dataset.
%   Delegates every read to HDF5LazyArray and counts the calls. Pass it to
%   the DataStub constructor to count how often code under test reads the
%   dataset.
%
%   An empty load_mat_style selection counts twice, because HDF5LazyArray
%   reads the first element through load_mat_style to get the data type.

    properties (SetAccess = private)
        % LoadCount - Number of calls to load_mat_style and load_h5_style.
        LoadCount (1,1) double = 0
    end

    methods
        function obj = HDF5LazyArraySpy(filename, path)
            arguments
                filename (1,1) string
                path (1,1) string
            end
            obj@io.backend.hdf5.HDF5LazyArray(filename, path);
        end

        function data = load_mat_style(obj, varargin)
            obj.LoadCount = obj.LoadCount + 1;
            data = load_mat_style@io.backend.hdf5.HDF5LazyArray(obj, varargin{:});
        end

        function data = load_h5_style(obj, varargin)
            obj.LoadCount = obj.LoadCount + 1;
            data = load_h5_style@io.backend.hdf5.HDF5LazyArray(obj, varargin{:});
        end
    end
end
