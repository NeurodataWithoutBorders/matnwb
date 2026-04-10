function vecHeight = getColumnHeight(VectorData)
    if isempty(VectorData)
        vecHeight = 0;
    else
        vecHeight = getDataHeight(VectorData.data);
    end
end

function vecHeight = getDataHeight(data)
    if isempty(data)
        vecHeight = 0;
    elseif isa(data, 'types.untyped.DataPipe')
        if data.isBound
            vecHeight = data.offset;
        elseif ~isscalar(data.internal.data) && isvector(data.internal.data)
            vecHeight = length(data.internal.data); % datapipe axis can be misleading if vector.
        else
            vecHeight = size(data.internal.data, data.axis);
        end
    elseif isa(data, 'types.untyped.DataStub')
        vecHeight = data.dims(end);
    elseif isscalar(data) && isstruct(data) % compound type (struct)
        dataFieldNames = fieldnames(data);
        if isempty(dataFieldNames)
            vecHeight = 0;
        else
            vecHeight = zeros(size(dataFieldNames));
            for iField = 1:length(dataFieldNames)
                field = dataFieldNames{iField};
                vecHeight(iField) = getDataHeight(data.(field));
            end
        end
    elseif istable(data) % compound type (table)
        vecHeight = height(data);
    elseif isscalar(data) || ~isvector(data)
        vecHeight = size(data, ndims(data));
    else
        vecHeight = size(data, find(1 < size(data)));
    end
end
