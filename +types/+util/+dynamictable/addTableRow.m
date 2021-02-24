function addTableRow(DynamicTable, subTable, varargin)
p = inputParser();
p.StructExpand = false;
addParameter(p, 'tablepath', '', @(x)ischar(x)); % required for ragged arrays.
parse(p, varargin{:});

rowNames = subTable.VariableNames;
missingColumns = setdiff(DynamicTable.colnames, rowNames);
assert(isempty(missingColumns),...
    'MatNWB:DynamicTable:AddRow:MissingColumns',...
    'Missing columns { %s }', strjoin(missingColumns, ', '));

specifiesId = ~any(strcmp(subTable.VariableNames, 'id'));
if specifiesId
    validateattributes(subTable.id, {'numeric'}, {'vector'});
end

TypeMap = types.util.dynamictable.getTypeMap(DynamicTable);
for i = 1:length(rowNames)
    rn = rowNames{i};
    rv = subTable.(rn);
    
    if isKey(TypeMap, rn)
        rv = validateType(TypeMap(rn), rv);
    end
    
    % instantiate vector index here because it's dependent on the table
    % fullpath.
    vecIndName = types.util.dynamictable.getIndex(DynamicTable, rn);
    if isempty(vecIndName) && ~iscellstr(rv) && iscell(rv)
        vecIndName = types.util.dynamictable.addVecInd(DynamicTable, rn, p.Results.tablepath);
    end
    if ~iscell(rv) || iscellstr(rv)
        rv = {rv};
    end
    for i = 1:length(rv)
        types.util.dynamictable.addRawData(DynamicTable, rn, rv{i}, vecIndName);
    end
end

if specifiesId
    return;
end

if isa(DynamicTable.id.data, 'types.untyped.DataPipe')
    newStartId = DynamicTable.id.data.offset;
    DynamicTable.id.data.append(DynamicTable.id.data.offset);
else
    newStartId = length(DynamicTable.id.data);
end

idRange = (newStartId:(newStartId+height(t))) .';
if isa(DynamicTable.id.data, 'types.untyped.DataPipe')
    DynamicTable.id.data.append(idRange);
else
    DynamicTable.id.data = [DynamicTable.id.data; idRange];
end
end

function validateType(TypeStruct, rv)
if strcmp(TypeStruct.type, 'cellstr')
    assert(iscellstr(rv) || (ischar(rv) && 1 == size(rv, 1)),...
        'MatNWB:DynamicTable:AddRow:InvalidType',...
        'Type of value must be a cell array of character vectors or a scalar character');
else
    if ~iscell(rv)
        rv = {rv};
    end
    for i = 1:length(rv)
        validateattributes(rv{i}, {TypeStruct.type}, {'size', [NaN TypeStruct.dims(2:end)]});
    end
end
end