function vecHeight = getColumnHeight(VectorData)
    if isempty(VectorData)
        vecHeight = 0;
    else
        vecHeight = getDataHeight(VectorData.data);
    end
end

function vecHeight = getDataHeight(data)
    if matnwb.preference.shouldFlipDimensions()
        rowDimension = @(d) ndims(d);  % matlab_style: row axis is last dimension
    else
        rowDimension = @(d) 1;         % schema_style: row axis is first dimension
    end

    if isempty(data)
        vecHeight = 0;
    elseif isa(data, 'types.untyped.DataPipe')
        if data.isBound
            % Bound DataPipes can have an ambiguous inferred axis when a dataset
            % is extendable in multiple dimensions. Use the loaded shape instead,
            % where DynamicTable row dimension maps to the last axis in
            % matlab_style and the first axis in schema_style.
            dataDims = size(data);
            if matnwb.preference.shouldFlipDimensions()
                vecHeight = dataDims(end);
            else
                vecHeight = dataDims(1);
            end
        elseif isempty(data.internal.data)
            vecHeight = 0;
        elseif ~isscalar(data.internal.data) && isvector(data.internal.data)
            vecHeight = length(data.internal.data); % datapipe axis can be misleading if vector.
        else
            vecHeight = size(data.internal.data, data.axis);
        end
    elseif isa(data, 'types.untyped.DataStub')
        if matnwb.preference.shouldFlipDimensions()
            vecHeight = data.dims(end);
        else
            vecHeight = data.dims(1);
        end
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
        vecHeight = size(data, rowDimension(data));
    else
        vecHeight = size(data, find(1 < size(data)));
    end
end
