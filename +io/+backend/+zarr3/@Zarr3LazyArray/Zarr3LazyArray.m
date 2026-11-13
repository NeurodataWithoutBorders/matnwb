classdef Zarr3LazyArray < io.backend.base.LazyArray
% Zarr3LazyArray - Zarr v3-backed lazy dataset access implementation.
%
% Zarr v3 stores written by Python NWB tools keep numpy's row-major shape
% order, and zarr-matlab reads them in that order, so the storage order is
% the reverse of MatNWB's (see isStorageOrderReversed): the base class
% reverses the dims, the subscripts and the data of rank 2 and higher
% arrays. A rank-1 array is the same in either order.
%
% zarr.Array.read reads a contiguous hyperslab, decoding every chunk it
% touches, so a selection is read through the hyperslab that bounds it and
% a scattered linear selection element by element (see
% getBoundingBoxLimits).

    properties (Access = private)
        % ArrayNode - zarr.Array for the wrapped dataset. Supplied by
        % io.backend.zarr3.Zarr3Reader, which opens it from the store's
        % consolidated metadata; otherwise opened by resolveArray on first
        % read. Cached, so that repeated reads reuse a single open array
        % rather than reopening the store.
        ArrayNode = []

        % ObjectReferenceFields - Names of the compound fields that hold
        % object references rather than literal data, or empty for a
        % non-compound dataset. Supplied by io.backend.zarr3.Zarr3Reader,
        % which has already read them; getObjectReferenceFields falls back
        % to reading them from the array when a Zarr3LazyArray is
        % constructed directly (see
        % io.backend.zarr3.internal.getObjectReferenceFields).
        ObjectReferenceFields (1,:) string = string.empty(1, 0)
    end

    methods
        function obj = Zarr3LazyArray(filename, datasetPath, dims, dataType, objectReferenceFields, options)
            arguments
                filename (1,1) string
                datasetPath (1,1) string
                dims double = []
                dataType = []
                objectReferenceFields (1,:) string = string.empty(1, 0)
                % ArrayNode - The dataset's zarr.Array, if already open. Its
                % class, not its size, is validated: zarr.Array redefines
                % size to report the dataset's shape.
                options.ArrayNode {mustBeA(options.ArrayNode, ["zarr.Array", "double"])} = []
            end
            obj@io.backend.base.LazyArray(filename, datasetPath, dims, dataType);
            obj.ObjectReferenceFields = objectReferenceFields;
            obj.ArrayNode = options.ArrayNode;
        end

        function refreshSizeInfo(obj)
            dims = obj.toMatnwbOrder(double(obj.resolveArray().shape));
            obj.setSizeInfo(dims, dims);
        end

        function dataType = resolveDataType(obj)
            % For a structured (compound) array, dataType is a compound
            % type descriptor struct (see
            % io.backend.zarr3.internal.getCompoundTypeDescriptor), not a plain
            % class name -- required by
            % types.util.checkDtype/types.untyped.DataStub.isCompoundType.
            % io.backend.zarr3.Zarr3Reader normally passes this in at
            % construction (avoiding this lazy path entirely); it is
            % reproduced here only as a fallback for a Zarr3LazyArray
            % constructed directly without one.
            arrayNode = obj.resolveArray();
            info = zarr.internal.dtype_info(arrayNode.meta.dataType, arrayNode.meta.dataTypeConfig);
            if info.isStructured
                dataType = io.backend.zarr3.internal.getCompoundTypeDescriptor(info, obj.getObjectReferenceFields());
            else
                dataType = char(info.matlabClass);
            end
        end

        function data = load_h5_style(obj, varargin)
            rank = numel(obj.dims);
            if isempty(varargin)
                data = obj.readHyperslab(ones(1, rank), inf(1, rank));
                return
            end

            assert(length(varargin) ~= 1, 'NWB:DataStub:InvalidNumArguments',...
                'calling load_h5_style with a single space id is no longer supported.');
            data = obj.readHyperslab(varargin{:});
        end
    end

    methods (Access = protected)
        function data = readSubscripts(obj, selection)
        % readSubscripts - Read every combination of per-dimension indices.
        %
        % The hyperslab that bounds the selection is read, and the selected
        % indices are taken from it. A selection of every index is read
        % without bounds.
            arrayNode = obj.resolveArray();
            if all(cellfun(@ischar, selection))
                data = obj.postProcessCompound(arrayNode.read());
                return
            end
            if any(cellfun(@(indices) ~ischar(indices) && isempty(indices), selection))
                data = obj.readEmptySelection(selection);
                return
            end

            shape = double(arrayNode.shape);
            start = ones(1, numel(selection));
            count = shape;
            localSelection = selection;
            for iDimension = 1:numel(selection)
                indices = selection{iDimension};
                if ~ischar(indices)
                    start(iDimension) = indices(1);
                    count(iDimension) = indices(end) - indices(1) + 1;
                    localSelection{iDimension} = indices - indices(1) + 1;
                end
            end
            box = arrayNode.read(start, count);
            data = obj.postProcessCompound(box(localSelection{:}));
        end

        function values = readPoints(obj, subscripts)
        % readPoints - Read single elements, one read per element.
            arrayNode = obj.resolveArray();
            numPoints = size(subscripts, 1);
            unitCount = ones(1, size(subscripts, 2));
            points = cell(numPoints, 1);
            for iPoint = 1:numPoints
                points{iPoint} = arrayNode.read(subscripts(iPoint, :), unitCount);
            end
            values = obj.postProcessCompound(vertcat(points{:}));
        end

        function tf = isStorageOrderReversed(~)
            tf = true;
        end

        function [maxOverread, minElements] = getBoundingBoxLimits(~)
        % getBoundingBoxLimits - When a linear selection is read as a box.
        %
        % Reading an element decodes its whole chunk, so a box that holds
        % up to four times the selection, or up to 1e5 elements, is
        % cheaper than reading its elements one by one. A larger box can
        % be most of a large sparse dataset.
            maxOverread = 4;
            minElements = 1e5;
        end
    end

    methods (Access = private)
        function arrayNode = resolveArray(obj)
            if isempty(obj.ArrayNode)
                relativePath = io.backend.zarr3.internal.stripLeadingSlash(obj.DatasetPath);
                obj.ArrayNode = io.backend.zarr3.internal.openNode(obj.Filename, relativePath);
            end
            arrayNode = obj.ArrayNode;
        end

        function referenceFields = getObjectReferenceFields(obj)
            if ~isempty(obj.ObjectReferenceFields)
                referenceFields = obj.ObjectReferenceFields;
            else
                referenceFields = io.backend.zarr3.internal.getObjectReferenceFields(obj.resolveArray().attrs);
            end
        end

        function data = postProcessCompound(obj, data)
        % postProcessCompound - Reshape compound records to struct of arrays.
        %
        % Converts zarr-matlab's array-of-records (one struct per element)
        % into the "struct of arrays" shape (one scalar struct, each field an
        % Nx1 array) that io.backend.hdf5.@HDF5LazyArray/load_h5_style.m
        % produces via io.parseCompound. Any field that holds an object
        % reference (see io.backend.zarr3.internal.getObjectReferenceFields) is
        % decoded into a types.untyped.ObjectView array along the way (see
        % io.backend.zarr3.internal.decodeObjectReferences), and text is returned as
        % cellstr so that a compound dataset reads back as the same MATLAB
        % types on either backend.

            if ~isstruct(data)
                return
            end

            referenceFields = obj.getObjectReferenceFields();
            fieldNames = fieldnames(data);
            n = numel(data);
            converted = struct();
            for iField = 1:numel(fieldNames)
                name = fieldNames{iField};
                rawValues = {data.(name)};
                if ismember(name, referenceFields)
                    objectViews = io.backend.zarr3.internal.decodeObjectReferences(string(rawValues));
                    converted.(name) = reshape(objectViews, n, 1);
                elseif ~isempty(rawValues) && isstring(rawValues{1})
                    % zarr-matlab returns both Zarr text types as MATLAB
                    % strings. io.parseCompound yields a cellstr column for
                    % an HDF5 compound's variable-length string field, and
                    % the type descriptor reports these fields as 'char'
                    % (see io.backend.zarr3.internal.getCompoundTypeDescriptor), so
                    % convert to keep the value and its declared type
                    % consistent with the HDF5 backend.
                    converted.(name) = reshape(cellstr(string(rawValues)), n, 1);
                else
                    converted.(name) = reshape([rawValues{:}], n, 1);
                end
            end
            data = converted;
        end

        function data = readEmptySelection(obj, selection)
        % readEmptySelection - An empty array of the selection's shape and class.
        %
        % The class is taken from the first element, read on its own.
            arrayNode = obj.resolveArray();
            shape = double(arrayNode.shape);
            sample = obj.postProcessCompound(arrayNode.read(ones(1, numel(shape)), ones(1, numel(shape))));
            outputSize = shape;
            for iDimension = 1:numel(selection)
                if ~ischar(selection{iDimension})
                    outputSize(iDimension) = numel(selection{iDimension});
                end
            end
            outputSize = [outputSize, ones(1, 2 - numel(outputSize))];
            if isstruct(sample)
                data = structfun(@(values) repmat(values(1), outputSize), sample, ...
                    'UniformOutput', false);
            else
                data = repmat(sample(1), outputSize);
            end
        end
    end
end
