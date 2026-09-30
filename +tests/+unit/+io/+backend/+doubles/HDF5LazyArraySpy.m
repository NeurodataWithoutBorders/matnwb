classdef HDF5LazyArraySpy < io.backend.hdf5.HDF5LazyArray
% HDF5LazyArraySpy - Test spy that records reads from an HDF5 dataset.
%   Delegates every read to HDF5LazyArray and records the calls. Pass it to
%   the DataStub constructor to see how often, and for which elements, code
%   under test reads the dataset.
%
%   A selection is recorded twice when the read passes it on to
%   load_mat_style: an empty load_mat_style selection, which reads the
%   first element to get the data type, and a loadSelections selection that
%   is not read as a hyperslab.

    properties (SetAccess = private)
        % LoadCount - Number of calls to load_mat_style, load_h5_style and
        % loadSelections.
        LoadCount (1,1) double = 0

        % Selections - Subscripts of each selection read by load_mat_style
        % or loadSelections, one cell array per selection.
        Selections (1,:) cell = {}
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
            obj.Selections = {};
        end

        function data = load_mat_style(obj, varargin)
            obj.LoadCount = obj.LoadCount + 1;
            obj.Selections{end+1} = varargin;
            data = load_mat_style@io.backend.hdf5.HDF5LazyArray(obj, varargin{:});
        end

        function data = load_h5_style(obj, varargin)
            obj.LoadCount = obj.LoadCount + 1;
            data = load_h5_style@io.backend.hdf5.HDF5LazyArray(obj, varargin{:});
        end

        function data = loadSelections(obj, selections)
            obj.LoadCount = obj.LoadCount + 1;
            obj.Selections = [obj.Selections, reshape(selections, 1, [])];
            data = loadSelections@io.backend.hdf5.HDF5LazyArray(obj, selections);
        end
    end
end
