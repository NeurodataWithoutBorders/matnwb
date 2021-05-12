function addVarargRow(DynamicTable, varargin)
p = inputParser();
p.KeepUnmatched = true;
p.StructExpand = false;
addParameter(p, 'tablepath', '', @(x)ischar(x)); % required for ragged arrays.
addParameter(p, 'id', []); % `id` override but doesn't actually show up in `colnames`

for i = 1:length(DynamicTable.colnames)
    addParameter(p, DynamicTable.colnames{i}, []);
end

parse(p, varargin{:});

assert(isempty(fieldnames(p.Unmatched)),...
    'MatNWB:DynamicTable:AddRow:InvalidColumns',...
    'Invalid column name(s) { %s }', strjoin(fieldnames(p.Unmatched), ', '));

rowNames = fieldnames(p.Results);

% not using setDiff because we want to retain set order.
rowNames(strcmp(rowNames, 'tablepath') | strcmp(rowNames, 'id')) = []; 

missingColumns = setdiff(p.UsingDefaults, {'tablepath', 'id'});
assert(isempty(missingColumns),...
    'MatNWB:DynamicTable:AddRow:MissingColumns',...
    'Missing columns { %s }', strjoin(missingColumns, ', '));

specifiesId = ~any(strcmp(p.UsingDefaults, 'id'));
if specifiesId
    validateattributes(p.Results.id, {'numeric'}, {'scalar'});
end

TypeMap = types.util.dynamictable.getTypeMap(DynamicTable);
for i = 1:length(rowNames)
    rn = rowNames{i};
    rv = p.Results.(rn);
    
    if isKey(TypeMap, rn)
        validateType(TypeMap(rn), rv);    
    end
    assert(iscellstr(rv) || ~iscell(rv),...
            'MatNWB:DynamicTable:AddRow:InvalidCellArray',...
            'Cell arrays that are not cell strings are not allowed.');
    if ischar(rv)
        rv = {rv};
    end
    
    % instantiate vector index here because it's dependent on the table
    % fullpath.
    vecIndName = types.util.dynamictable.getIndex(DynamicTable, rn);
    if isempty(vecIndName) && (~isempty(p.Results.tablepath) || size(rv, 1) > 1)
        vecIndName = types.util.dynamictable.addVecInd(DynamicTable, rn, p.Results.tablepath);
    end
    types.util.dynamictable.addRawData(DynamicTable, rn, rv, vecIndName);
end

if specifiesId
    newId = p.Results.id;
elseif isa(DynamicTable.id.data, 'types.untyped.DataPipe')
    newId = DynamicTable.id.data.offset;
    DynamicTable.id.data.append(DynamicTable.id.data.offset);
else
    newId = length(DynamicTable.id.data);
end

if isa(DynamicTable.id.data, 'types.untyped.DataPipe')
    DynamicTable.id.data.append(newId);
else
    DynamicTable.id.data = [DynamicTable.id.data; newId];
end
end

function validateType(TypeStruct, rv)
if strcmp(TypeStruct.type, 'cellstr')
    assert(iscellstr(rv) || (ischar(rv) && 1 == size(rv, 1)),...
        'MatNWB:DynamicTable:AddRow:InvalidType',...
        'Type of value must be a cell array of character vectors or a scalar character');
else
    validateattributes(rv, {TypeStruct.type}, {'size', [NaN TypeStruct.dims(2:end)]});
end
end