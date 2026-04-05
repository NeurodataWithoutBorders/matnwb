classdef Zarr2LazyArray < io.backend.base.LazyArray
% Zarr2LazyArray - Minimal Zarr v2-backed lazy dataset access implementation.

    methods
        function obj = Zarr2LazyArray(filename, path, dims, dataType)
            arguments
                filename (1,1) string
                path (1,1) string
                dims double = []
                dataType = []
            end
            obj@io.backend.base.LazyArray(filename, path, dims, dataType);
        end

        function refreshSizeInfo(obj)
            datasetInfo = obj.readDatasetInfo();
            dims = obj.normalizeDims(datasetInfo.Dataspace.Size);
            obj.setSizeInfo(dims, dims);
        end

        function dataType = resolveDataType(obj)
            datasetInfo = obj.readDatasetInfo();
            datasetDirectory = obj.resolveDatasetDirectory();
            dataType = io.internal.zarr2.getMatlabDataType(datasetDirectory, datasetInfo);
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
                return
            end

            [isSupported, fullSelection] = obj.tryBuildRegularSelection(varargin);
            if isSupported
                [start, count, stride] = obj.selectionToReadParameters(fullSelection);
                data = obj.readPartialData(start, count, stride);
                if obj.isCompoundArray(data)
                    data = obj.convertCompoundDataToTable(data);
                else
                    data = obj.applySelectionShape(data, varargin);
                end
            else
                data = obj.readAllData();
                data = data(varargin{:});
                if obj.isCompoundArray(data)
                    data = obj.convertCompoundDataToTable(data);
                end
            end
        end
    end

    methods (Access = private)
        function datasetInfo = readDatasetInfo(obj)
            reader = io.backend.zarr2.Zarr2Reader(obj.filename);
            datasetInfo = reader.readNodeInfo(obj.path);
        end

        function datasetDirectory = resolveDatasetDirectory(obj)
            relativePath = regexprep(char(obj.path), '^/', '');
            datasetDirectory = string(fullfile(obj.filename, relativePath));
        end

        function data = readAllData(obj)
            datasetInfo = obj.readDatasetInfo();
            datasetDirectory = obj.resolveDatasetDirectory();
            data = io.internal.zarr2.readDataset(datasetDirectory, datasetInfo);
        end

        function data = readPartialData(obj, start, count, stride)
            datasetDirectory = obj.resolveDatasetDirectory();
            if ~obj.supportsPartialRead()
                data = obj.readAllData();
                selection = cell(1, length(start));
                for iDimension = 1:length(start)
                    if isinf(count(iDimension))
                        stopIndex = obj.dims(iDimension);
                    else
                        stopIndex = start(iDimension) + (count(iDimension)-1) * stride(iDimension);
                    end
                    selection{iDimension} = start(iDimension):stride(iDimension):stopIndex;
                end
                data = data(selection{:});
                return
            end

            if any(isinf(count))
                count = floor((obj.dims - start) ./ stride) + 1;
            end

            [rawStart, rawCount, rawStride] = obj.toRawReadParameters(start, count, stride);
            data = io.backend.zarr2.mw.readArray( ...
                datasetDirectory, rawStart, rawCount, rawStride);
            data = io.internal.zarr2.readDataset( ...
                datasetDirectory, obj.readDatasetInfo(), data);
        end

        function tf = supportsPartialRead(obj)
            datasetInfo = obj.readDatasetInfo();
            datasetDirectory = obj.resolveDatasetDirectory();
            rawDatasetInfo = io.backend.zarr2.mw.readInfo(datasetDirectory);

            tf = ~(ischar(datasetInfo.Datatype) || isstring(datasetInfo.Datatype) ...
                && lower(string(datasetInfo.Datatype)) == "object") ...
                && ~(isfield(rawDatasetInfo, "dtype") && obj.isObjectRawDtype(rawDatasetInfo.dtype));
        end

        function tf = isCompoundArray(obj, data)
            tf = isstruct(obj.dataType) && isstruct(data);
        end

        function data = convertCompoundDataToTable(~, data)
            data = struct2table(data(:));
        end

        function tf = isObjectRawDtype(~, rawDtype)
            tf = (ischar(rawDtype) || isstring(rawDtype)) && strcmp(string(rawDtype), "|O");
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
            tf = all(stepSizes > 0) && numel(unique(stepSizes)) == 1;
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

        function [rawStart, rawCount, rawStride] = toRawReadParameters(obj, start, count, stride)
            if isscalar(obj.dims)
                rawStart = start;
                rawCount = count;
                rawStride = stride;
            else
                rawStart = fliplr(start);
                rawCount = fliplr(count);
                rawStride = fliplr(stride);
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

        function dims = normalizeDims(~, dims)
            dims = double(dims);
            if isempty(dims) || isscalar(dims)
                return
            end
            dims = fliplr(dims);
        end
    end
end
