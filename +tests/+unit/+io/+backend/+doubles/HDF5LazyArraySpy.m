classdef HDF5LazyArraySpy < io.backend.hdf5.HDF5LazyArray
% HDF5LazyArraySpy - Test spy that records reads from an HDF5 dataset.
%   Delegates every read to HDF5LazyArray and records the calls. Pass it to
%   the DataStub constructor to see how often, and for which elements, code
%   under test reads the dataset.
%
%   An empty load_mat_style selection is recorded twice, because
%   HDF5LazyArray reads the first element through load_mat_style to get the
%   data type.

    properties (SetAccess = private)
        % LoadCount - Number of calls to load_mat_style and load_h5_style.
        LoadCount (1,1) double = 0

        % MatStyleSelections - Subscripts passed to each load_mat_style
        % call, one cell array per call.
        MatStyleSelections (1,:) cell = {}
    end

    methods
        function obj = HDF5LazyArraySpy(filename, path)
            arguments
                filename (1,1) string
                path (1,1) string
            end
            obj@io.backend.hdf5.HDF5LazyArray(filename, path);
        end

        function reset(obj)
            % reset - Forget the calls recorded so far.
            obj.LoadCount = 0;
            obj.MatStyleSelections = {};
        end

        function data = load_mat_style(obj, varargin)
            obj.LoadCount = obj.LoadCount + 1;
            obj.MatStyleSelections{end+1} = varargin;
            data = load_mat_style@io.backend.hdf5.HDF5LazyArray(obj, varargin{:});
        end

        function data = load_h5_style(obj, varargin)
            obj.LoadCount = obj.LoadCount + 1;
            data = load_h5_style@io.backend.hdf5.HDF5LazyArray(obj, varargin{:});
        end
    end
end
