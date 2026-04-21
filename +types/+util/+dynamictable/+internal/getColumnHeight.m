function columnHeight = getColumnHeight(column)
% getColumnHeight - Return the stored height of a DynamicTable column object.
%
% This helper inspects the underlying stored data shape only. It does not
% resolve VectorIndex chains to determine DynamicTable row height.

    if isempty(column)
        columnHeight = 0;
    else
        columnHeight = getDataHeight(column.data);
    end
end

function columnHeight = getDataHeight(data)
    if isempty(data)
        columnHeight = 0;
    elseif isa(data, 'types.untyped.DataPipe')
        if data.isBound
            % Bound DataPipes can have an ambiguous inferred axis when a dataset
            % is extendable in multiple dimensions. Use the loaded MATLAB shape
            % instead, where DynamicTable row dimension maps to the last axis.
            dataDims = size(data);
            columnHeight = dataDims(end);
        elseif isempty(data.internal.data)
            columnHeight = 0;
        elseif ~isscalar(data.internal.data) && isvector(data.internal.data)
            columnHeight = length(data.internal.data); % datapipe axis can be misleading if vector.
        else
            columnHeight = size(data.internal.data, data.axis);
        end
    elseif isa(data, 'types.untyped.DataStub')
        columnHeight = data.dims(end);
    elseif isscalar(data) && isstruct(data) % compound type (struct)
        dataFieldNames = fieldnames(data);
        if isempty(dataFieldNames)
            columnHeight = 0;
        else
            columnHeight = zeros(size(dataFieldNames));
            for iField = 1:length(dataFieldNames)
                field = dataFieldNames{iField};
                columnHeight(iField) = getDataHeight(data.(field));
            end
        end
    elseif istable(data) % compound type (table)
        columnHeight = height(data);
    elseif isscalar(data) || ~isvector(data)
        columnHeight = size(data, ndims(data));
    else
        columnHeight = size(data, find(1 < size(data)));
    end
end
