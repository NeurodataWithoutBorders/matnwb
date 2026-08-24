classdef Zarr3LazyArray < io.backend.base.LazyArray
% Zarr3LazyArray - Zarr v3-backed lazy dataset access implementation.
%
% Zarr v3 stores may be written by Python NWB tools using numpy/row-major
% shape order. For rank >= 2 arrays, dims and data are reversed to match
% MatNWB's H5-style convention (see io.internal.zarr3.normalizeDatasetDimensions).
% A rank-1 array needs no correction: zarr-matlab already returns it as a
% MATLAB column vector.

    properties (Access = private)
        % ArrayNode - zarr.Array for the wrapped dataset. Opened lazily by
        % resolveArray on first read and cached, so that repeated reads
        % reuse a single open array rather than reopening the store.
        ArrayNode = []

        % ObjectReferenceFields - Names of the compound fields that hold
        % object references rather than literal data, or empty for a
        % non-compound dataset. Supplied by io.backend.zarr3.Zarr3Reader,
        % which has already read them; getObjectReferenceFields falls back
        % to reading them from the array when a Zarr3LazyArray is
        % constructed directly (see
        % io.internal.zarr3.getObjectReferenceFields).
        ObjectReferenceFields (1,:) string = string.empty(1, 0)
    end

    methods
        function obj = Zarr3LazyArray(filename, datasetPath, dims, dataType, objectReferenceFields)
            arguments
                filename (1,1) string
                datasetPath (1,1) string
                dims double = []
                dataType = []
                objectReferenceFields (1,:) string = string.empty(1, 0)
            end
            obj@io.backend.base.LazyArray(filename, datasetPath, dims, dataType);
            obj.ObjectReferenceFields = objectReferenceFields;
        end

        function refreshSizeInfo(obj)
            arrayNode = obj.resolveArray();
            dims = double(arrayNode.shape);
            if numel(dims) >= 2
                dims = fliplr(dims);
            end
            obj.setSizeInfo(dims, dims);
        end

        function dataType = resolveDataType(obj)
            % For a "structured" (compound) array, dataType is a compound
            % type descriptor struct (see
            % io.internal.zarr3.getCompoundTypeDescriptor), not a plain
            % class name -- required by
            % types.util.checkDtype/types.untyped.DataStub.isCompoundType.
            % io.backend.zarr3.Zarr3Reader normally passes this in at
            % construction (avoiding this lazy path entirely); it is
            % reproduced here only as a fallback for a Zarr3LazyArray
            % constructed directly without one.
            arrayNode = obj.resolveArray();
            info = zarr.internal.dtype_info(arrayNode.meta.dataType, arrayNode.meta.dataTypeConfig);
            if info.zarrType == "structured"
                dataType = io.internal.zarr3.getCompoundTypeDescriptor(info, obj.getObjectReferenceFields());
            else
                dataType = char(info.matlabClass);
            end
        end

        function data = load_h5_style(obj, varargin)
            if isempty(varargin)
                data = obj.readAllData();
                return
            end

            assert(length(varargin) ~= 1, 'NWB:DataStub:InvalidNumArguments',...
                'calling load_h5_style with a single space id is no longer supported.');

            start = varargin{1};
            count = varargin{2};
            if length(varargin) >= 3
                stride = varargin{3};
            else
                stride = ones(size(start));
            end
            data = obj.readPartialData(start, count, stride);
        end

        function data = load_mat_style(obj, varargin)
            if isempty(varargin)
                data = obj.readAllData();
                if isstruct(data)
                    data = struct2table(data);
                end
                return
            end

            [isSupported, fullSelection] = obj.tryBuildRegularSelection(varargin);
            if isSupported
                [start, count, stride] = obj.selectionToReadParameters(fullSelection);
                data = obj.readPartialData(start, count, stride);
                if isstruct(data)
                    % Record selection already happened during the partial
                    % read; matching io.backend.hdf5.@HDF5LazyArray's
                    % compound convention, the selected records are
                    % returned as a table rather than reshaped further.
                    data = struct2table(data);
                else
                    data = obj.applySelectionShape(data, varargin);
                end
            else
                data = obj.readAllData();
                if isstruct(data)
                    data = struct2table(data);
                    data = data(varargin{:}, :);
                else
                    data = data(varargin{:});
                end
            end
        end
    end

    methods (Access = private)
        function arrayNode = resolveArray(obj)
            if isempty(obj.ArrayNode)
                relativePath = io.internal.zarr3.stripLeadingSlash(obj.DatasetPath);
                obj.ArrayNode = zarr.open(obj.Filename, Path=relativePath);
            end
            arrayNode = obj.ArrayNode;
        end

        function referenceFields = getObjectReferenceFields(obj)
            if ~isempty(obj.ObjectReferenceFields)
                referenceFields = obj.ObjectReferenceFields;
            else
                referenceFields = io.internal.zarr3.getObjectReferenceFields(obj.resolveArray().attrs);
            end
        end

        function data = postProcessCompound(obj, data)
        % postProcessCompound - Reshape compound records to struct of arrays.
        %
        % Converts zarr-matlab's array-of-records (one struct per element)
        % into the "struct of arrays" shape (one scalar struct, each field an
        % Nx1 array) that io.backend.hdf5.@HDF5LazyArray/load_h5_style.m
        % produces via io.parseCompound. Any field that holds an object
        % reference (see io.internal.zarr3.getObjectReferenceFields) is
        % decoded into a types.untyped.ObjectView array along the way (see
        % io.internal.zarr3.decodeObjectReferences).

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
                    objectViews = io.internal.zarr3.decodeObjectReferences(string(rawValues));
                    converted.(name) = reshape(objectViews, n, 1);
                else
                    converted.(name) = reshape([rawValues{:}], n, 1);
                end
            end
            data = converted;
        end

        function data = readAllData(obj)
            arrayNode = obj.resolveArray();
            data = arrayNode.read();
            data = io.internal.zarr3.normalizeDatasetDimensions(data, numel(arrayNode.shape));
            data = obj.postProcessCompound(data);
        end

        function data = readPartialData(obj, start, count, stride)
            arrayNode = obj.resolveArray();
            if any(isinf(count))
                count(isinf(count)) = obj.dims(isinf(count)) - start(isinf(count)) + 1;
            end

            % start/count/stride arrive in MatNWB's H5-style dims order
            % (obj.dims); reverse to raw Zarr/numpy order for rank >= 2
            % before calling zarr.Array.read (see refreshSizeInfo).
            rank = numel(start);
            if rank >= 2
                rawStart = fliplr(start);
                rawCount = fliplr(count);
                rawStride = fliplr(stride);
            else
                rawStart = start;
                rawCount = count;
                rawStride = stride;
            end

            if all(rawStride == 1)
                data = arrayNode.read(rawStart, rawCount);
            else
                % zarr.Array.read has no native stride support: read the
                % contiguous bounding box spanning the strided selection,
                % then subselect the stride in MATLAB.
                boxedSpan = (rawCount - 1) .* rawStride + 1;
                boxed = arrayNode.read(rawStart, boxedSpan);
                selection = cell(1, numel(rawStart));
                for iDimension = 1:numel(rawStart)
                    selection{iDimension} = 1:rawStride(iDimension):boxedSpan(iDimension);
                end
                data = boxed(selection{:});
            end
            data = io.internal.zarr3.normalizeDatasetDimensions(data, rank);
            data = obj.postProcessCompound(data);
        end

        function [isSupported, fullSelection] = tryBuildRegularSelection(obj, userSelection)
            dataDimensions = obj.dims;
            isSupported = true;
            fullSelection = cell(1, length(dataDimensions));

            if isscalar(userSelection) && isempty(userSelection{1})
                isSupported = false;
                return
            end

            if isscalar(userSelection) && ~ischar(userSelection{1})
                isSupported = false;
                return
            end

            isDanglingGroup = ischar(userSelection{end});
            for iDimension = 1:length(dataDimensions)
                if iDimension > length(userSelection) && ~isDanglingGroup
                    fullSelection{iDimension} = 1;
                elseif (iDimension > length(userSelection) && isDanglingGroup) ...
                        || ischar(userSelection{iDimension})
                    fullSelection{iDimension} = 1:dataDimensions(iDimension);
                else
                    selection = userSelection{iDimension};
                    if ~obj.isRegularAscendingSelection(selection)
                        isSupported = false;
                        return
                    end
                    fullSelection{iDimension} = selection;
                end
            end
        end

        function tf = isRegularAscendingSelection(~, selection)
            tf = isnumeric(selection) ...
                && isreal(selection) ...
                && all(isfinite(selection)) ...
                && all(selection > 0) ...
                && all(selection == floor(selection));
            if ~tf
                return
            end
            if isscalar(selection)
                return
            end

            stepSizes = diff(selection);
            tf = all(stepSizes > 0) && isscalar(unique(stepSizes));
        end

        function [start, count, stride] = selectionToReadParameters(~, selection)
            start = zeros(1, numel(selection));
            count = zeros(1, numel(selection));
            stride = ones(1, numel(selection));

            for iDimension = 1:numel(selection)
                currentSelection = selection{iDimension};
                start(iDimension) = currentSelection(1);
                count(iDimension) = numel(currentSelection);
                if numel(currentSelection) > 1
                    stride(iDimension) = currentSelection(2) - currentSelection(1);
                end
            end
        end

        function data = applySelectionShape(obj, data, userSelection)
            expectedSize = obj.getExpectedSize(userSelection);
            if isequal(size(data), expectedSize)
                return
            end
            data = reshape(data, expectedSize);
        end

        function expectedSize = getExpectedSize(obj, userSelection)
            dataDimensions = obj.dims;
            expectedSize = dataDimensions;
            for iSelection = 1:length(userSelection)
                if ~ischar(userSelection{iSelection})
                    expectedSize(iSelection) = length(userSelection{iSelection});
                end
            end

            if ischar(userSelection{end})
                selectedDimensionIndex = length(userSelection);
                expectedSize = [expectedSize(1:(selectedDimensionIndex-1)), ...
                    prod(dataDimensions(selectedDimensionIndex:end))];
            else
                expectedSize = expectedSize(1:length(userSelection));
            end

            if isscalar(userSelection) && isscalar(expectedSize)
                if 1 < sum(1 < dataDimensions)
                    if ~ischar(userSelection{1}) && isrow(userSelection{1})
                        expectedSize = [1 expectedSize];
                    else
                        expectedSize = [expectedSize 1];
                    end
                else
                    if dataDimensions(1) == 1
                        expectedSize = [1 expectedSize];
                    else
                        expectedSize = [expectedSize 1];
                    end
                end
            end
        end
    end
end
