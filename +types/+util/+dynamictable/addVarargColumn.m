function addVarargColumn(DynamicTable, varargin)
    % parse inputs
    p = inputParser();
    p.KeepUnmatched = true;
    p.StructExpand = false;
    parse(p, varargin{:});
    newNames = DynamicTable.validate_colnames(fieldnames(p.Unmatched));
    NewData = p.Unmatched;

    % get current table height - assume id length reflects table height
    if isempty(DynamicTable.id)
        tableHeight = 0;
    else
        tableHeight = length(DynamicTable.id.data);
    end

    dataClassName = types.util.getVectorClassName();

    for iName = 1:length(newNames)
        % validate field values are the right type
        name = newNames{iName};
        assert(isa(NewData.(newNames{iName}), dataClassName) ...
            , 'NWB:DynamicTable:AddColumn:InvalidColumn' ...
            , [ ...
            'Column "%s" is not a valid VectorData type. ' ...
            'All added columns must be VectorData objects. ' ...
            'This function cannot be used with nested data, please use the "addRow" functions if ' ...
            'you wish to add data that needs to be nestable.'] ...
            , name);
    end

    for iName = 1:length(newNames)
        columnName = newNames{iName};
        NewColumn = NewData.(columnName);

        % check if heights match before adding column
        columnHeight = getColumnHeight(NewColumn.data);
        assert(columnHeight == tableHeight ...
            , 'NWB:DynamicTable:AddColumn:MissingRows' ...
            , 'Height of column "%s" (with height %d) does not match the pre-existant table height %d' ...
            , columnName, columnHeight, tableHeight);
        DynamicTable.vectordata.set(columnName, NewColumn);
    end
end

function v = getColumnHeight(columnData)
    if ischar(columnData)
        v = size(columnData, 1);
    elseif isa(columnData, 'types.untyped.DataPipe')
        v = columnData.offset;
    elseif isa(columnData, 'types.untyped.DataStub')
        newDims = columnData.dims;
        if isempty(newDims)
            v = 0;
        else
            v = newDims(1);
        end
    else
        v = length(columnData);
    end
end

