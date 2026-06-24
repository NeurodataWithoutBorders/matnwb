function addVarargRow(dynamicTable, varargin)
    arguments
        dynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
    end
    arguments (Repeating)
        varargin
    end

    parser = inputParser();
    parser.KeepUnmatched = true;
    parser.StructExpand = false;
    addParameter(parser, 'id', []); % `id` override but doesn't actually show up in `colnames`

    for iColumn = 1:length(dynamicTable.colnames)
        addParameter(parser, dynamicTable.colnames{iColumn}, []);
    end

    parse(parser, varargin{:});

    assert(isempty(fieldnames(parser.Unmatched)),...
        'NWB:DynamicTable:AddRow:InvalidColumns',...
        'Invalid column name(s) { %s }', strjoin(fieldnames(parser.Unmatched), ', '));

    rowNames = fieldnames(parser.Results);

    % not using setDiff because we want to retain set order.
    rowNames(strcmp(rowNames, 'id')) = [];

    missingColumns = setdiff(parser.UsingDefaults, {'id'});
    assert(isempty(missingColumns),...
        'NWB:DynamicTable:AddRow:MissingColumns',...
        'Missing columns { %s }', strjoin(missingColumns, ', '));

    specifiesId = ~any(strcmp(parser.UsingDefaults, 'id'));
    if specifiesId
        validateattributes(parser.Results.id, {'numeric'}, {'scalar'});
    end

    typeMap = types.util.dynamictable.getTypeMap(dynamicTable);
    for iRow = 1:length(rowNames)
        rowName = rowNames{iRow};
        rowValue = parser.Results.(rowName);

        if isKey(typeMap, rowName)
            rowValue = validateType(typeMap(rowName), rowValue, rowName);
        end

        types.util.dynamictable.addRawData(dynamicTable, rowName, rowValue);
    end

    if specifiesId
        newId = parser.Results.id;
    elseif isa(dynamicTable.id.data, 'types.untyped.DataPipe')
        newId = dynamicTable.id.data.offset;
    else
        newId = length(dynamicTable.id.data);
    end

    if isa(dynamicTable.id.data, 'types.untyped.DataPipe')
        dynamicTable.id.data.append(newId);
    else
        dynamicTable.id.data = [double(dynamicTable.id.data); newId];
    end
end

function rowValue = validateType(typeStruct, rowValue, rowName)
    arguments
        typeStruct (1,1) struct
        rowValue
        rowName {mustBeTextScalar}
    end

    if strcmp(typeStruct.type, 'cellstr')
        assert(iscellstr(rowValue) || (ischar(rowValue) && (isempty(rowValue) || 1 == size(rowValue, 1))),...
            'NWB:DynamicTable:AddRow:InvalidType',...
            'Type of value must be a cell array of character vectors or a scalar character');
    elseif iscell(rowValue)
        for iVal = 1:length(rowValue)
            validateType(typeStruct, rowValue{iVal}, rowName);
        end
    else
        rowValue = types.util.checkDtype(rowName, typeStruct.type, rowValue);
    end
end
