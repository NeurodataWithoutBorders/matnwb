function addVarargRow(DynamicTable, varargin)
    Parser = inputParser();
    Parser.KeepUnmatched = true;
    Parser.StructExpand = false;
    addParameter(Parser, 'id', []); % `id` override but doesn't actually show up in `colnames`

    for iColumn = 1:length(DynamicTable.colnames)
        addParameter(Parser, DynamicTable.colnames{iColumn}, []);
    end

    parse(Parser, varargin{:});

    assert(isempty(fieldnames(Parser.Unmatched))...
        , 'NWB:DynamicTable:AddRow:InvalidColumns'...
        , 'Invalid column name(s) { %s }', strjoin(fieldnames(Parser.Unmatched), ', '));

    rowNames = fieldnames(Parser.Results);

    % not using setDiff because we want to retain set order.
    rowNames(strcmp(rowNames, 'id')) = [];

    missingColumns = setdiff(Parser.UsingDefaults, {'id'});
    assert(isempty(missingColumns),...
        'NWB:DynamicTable:AddRow:MissingColumns',...
        'Missing columns { %s }', strjoin(missingColumns, ', '));

    specifiesId = ~any(strcmp(Parser.UsingDefaults, 'id'));
    if specifiesId
        validateattributes(Parser.Results.id, {'numeric'}, {'scalar'});
    end

    TypeMap = types.util.dynamictable.getTypeMap(DynamicTable);
    for iRow = 1:length(rowNames)
        rowName = rowNames{iRow};
        rowValue = Parser.Results.(rowName);

        if isKey(TypeMap, rowName)
            validateType(TypeMap(rowName), rowValue);
        end

        types.util.dynamictable.addRawData(DynamicTable, rowName, rowValue);
    end

    if specifiesId
        newId = Parser.Results.id;
    elseif isa(DynamicTable.id.data, 'types.untyped.DataPipe')
        newId = DynamicTable.id.data.offset;
    else
        newId = length(DynamicTable.id.data);
    end

    if isa(DynamicTable.id.data, 'types.untyped.DataPipe')
        DynamicTable.id.data.append(newId);
    else
        DynamicTable.id.data = [double(DynamicTable.id.data); newId];
    end
end

function validateType(TypeStruct, rowValue)
    if strcmp(TypeStruct.type, 'cellstr')
        assert(isstring(rowValue) ...
            || iscellstr(rowValue) ...
            || (ischar(rowValue) && (isempty(rowValue) || 1 == size(rowValue, 1))),...
            'NWB:DynamicTable:AddRow:InvalidType',...
            'Type of value must be a cell array of character vectors or a scalar character');
    elseif iscell(rowValue)
        for iVal = 1:length(rowValue)
            validateType(TypeStruct, rowValue{iVal});
        end
    else
        validateattributes(rowValue, {TypeStruct.type}, {});
    end
end
