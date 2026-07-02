function addVarargRow(DynamicTable, varargin)
% ADDVARARGROW Given a dynamic table and a set of keyword arguments for the row,
% add a single row to the dynamic table if using keywords, or multiple rows
% if using a table.
%
%  ADDVARARGROW(DT,col1,val1,col2,val2,...,coln,valn) append a single row
%  to the DynamicTable
%
%  ADDVARARGROW(DT,___,Name,Value) optional 'id'
%
% This function asserts the following:
% 1) The given keyword argument names match one of those ALREADY specified
%    by the DynamicTable (that is, colnames MUST be filled out).
% 2) If the dynamic table is non-empty, the types of the column value MUST
%    match the keyword value.
% 3) All horizontal data must match the width of the rest of the rows.
%    Variable length strings should use cell arrays each row.
% 4) The type of the data cannot be a cell array of numeric values if using
%    keyword arguments. For table appending mode, this is how ragged arrays
%    are represented.

    p = inputParser();
    p.KeepUnmatched = true;
    p.StructExpand = false;
    addParameter(p, 'id', []); % `id` override but doesn't actually show up in `colnames`

    for iColumn = 1:length(DynamicTable.colnames)
        addParameter(p, DynamicTable.colnames{iColumn}, []);
    end

    parse(p, varargin{:});

    assert(isempty(fieldnames(p.Unmatched)),...
        'NWB:DynamicTable:AddRow:InvalidColumns',...
        'Invalid column name(s) { %s }', strjoin(fieldnames(p.Unmatched), ', '));

    rowNames = fieldnames(p.Results);

    % not using setDiff because we want to retain set order.
    rowNames(strcmp(rowNames, 'id')) = [];

    missingColumns = setdiff(p.UsingDefaults, {'id'});
    assert(isempty(missingColumns),...
        'NWB:DynamicTable:AddRow:MissingColumns',...
        'Missing columns { %s }', strjoin(missingColumns, ', '));

    specifiesId = ~any(strcmp(p.UsingDefaults, 'id'));
    if specifiesId
        validateattributes(p.Results.id, {'numeric'}, {'scalar'});
    end

    TypeMap = types.util.dynamictable.getTypeMap(DynamicTable);
    for iRow = 1:length(rowNames)
        rn = rowNames{iRow};
        rv = p.Results.(rn);

        if isKey(TypeMap, rn)
            rv = validateType(TypeMap(rn), rv, rn);
        end

        types.util.dynamictable.addRawData(DynamicTable, rn, rv);
    end

    if specifiesId
        newId = p.Results.id;
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

function rv = validateType(TypeStruct, rv, rowName)
    if strcmp(TypeStruct.type, 'cellstr')
        assert(iscellstr(rv) || (ischar(rv) && (isempty(rv) || 1 == size(rv, 1))),...
            'NWB:DynamicTable:AddRow:InvalidType',...
            'Type of value must be a cell array of character vectors or a scalar character');
    elseif iscell(rv)
        for iVal = 1:length(rv)
            validateType(TypeStruct, rv{iVal}, rowName);
        end
    else
        rv = types.util.checkDtype(rowName, TypeStruct.type, rv);
    end
end
