function [columnHeight, hasEstablishedHeight] = getColumnHeight(column)
% getColumnHeight - Return the stored height of a DynamicTable column object.
%
% This helper inspects the underlying stored data shape only. It does not
% resolve VectorIndex chains to determine DynamicTable row height.

    if isempty(column)
        columnHeight = 0;
        hasEstablishedHeight = false;
    else
        [columnHeight, hasEstablishedHeight] = getDataHeight(column.data);
    end
end

function [columnHeight, hasEstablishedHeight] = getDataHeight(data)
    if isempty(data)
        columnHeight = 0;
        hasEstablishedHeight = false;
    elseif isa(data, 'types.untyped.DataPipe')
        if data.isBound
            % Bound DataPipes can have an ambiguous inferred axis when a dataset
            % is extendable in multiple dimensions. Use the loaded MATLAB shape
            % instead, where DynamicTable row dimension maps to the last axis.
            dataDims = size(data);
            columnHeight = dataDims(end);
            hasEstablishedHeight = true;
        else
            [columnHeight, hasEstablishedHeight] = getUnboundDataPipeHeight(data);
        end
    elseif isa(data, 'types.untyped.DataStub')
        columnHeight = data.dims(end);
        hasEstablishedHeight = true;
    elseif isscalar(data) && isstruct(data) % compound type (struct)
        dataFieldNames = fieldnames(data);
        if isempty(dataFieldNames)
            columnHeight = 0;
            hasEstablishedHeight = false;
        else
            columnHeight = zeros(size(dataFieldNames));
            hasEstablishedHeight = false(size(dataFieldNames));
            for iField = 1:length(dataFieldNames)
                field = dataFieldNames{iField};
                [columnHeight(iField), hasEstablishedHeight(iField)] = getDataHeight(data.(field));
            end
        end
    elseif istable(data) % compound type (table)
        columnHeight = height(data);
        hasEstablishedHeight = true;
    elseif isscalar(data) || ~isvector(data)
        columnHeight = size(data, ndims(data));
        hasEstablishedHeight = true;
    else
        columnHeight = size(data, find(1 < size(data)));
        hasEstablishedHeight = true;
    end
end

function [columnHeight, hasEstablishedHeight] = getUnboundDataPipeHeight(dataPipe)
    dataHeight = getQueuedDataHeight(dataPipe);
    columnHeight = dataPipe.offset + dataHeight;
    hasEstablishedHeight = columnHeight > 0;
end

function dataHeight = getQueuedDataHeight(dataPipe)
    if isempty(dataPipe.internal.data)
        dataHeight = 0;
    elseif ~isscalar(dataPipe.internal.data) && isvector(dataPipe.internal.data)
        % DataPipe axis can be misleading for vectors because vectors are
        % coerced to vertical arrays when bound to file.
        dataHeight = length(dataPipe.internal.data);
    else
        dataHeight = size(dataPipe.internal.data, dataPipe.axis);
    end
end
