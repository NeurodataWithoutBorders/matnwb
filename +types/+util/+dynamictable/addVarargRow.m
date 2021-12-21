function addVarargRow(DynamicTable, varargin)
p = inputParser();
p.KeepUnmatched = true;
p.StructExpand = false;
addParameter(p, 'id', []); % `id` override but doesn't actually show up in `colnames`

for i = 1:length(DynamicTable.colnames)
    addParameter(p, DynamicTable.colnames{i}, []);
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
for i = 1:length(rowNames)
    rn = rowNames{i};
    rv = p.Results.(rn);
    
    if isKey(TypeMap, rn)
        validateType(TypeMap(rn), rv);    
    end
    
    types.util.dynamictable.addRawData(DynamicTable, rn, rv);
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
    DynamicTable.id.data = [double(DynamicTable.id.data); newId];
end
end

function validateType(TypeStruct, rv)
if strcmp(TypeStruct.type, 'cellstr')
    assert(iscellstr(rv) || (ischar(rv) && (isempty(rv) || 1 == size(rv, 1))),...
        'NWB:DynamicTable:AddRow:InvalidType',...
        'Type of value must be a cell array of character vectors or a scalar character');
elseif iscell(rv)
    for iVal = 1:length(rv)
        validateType(TypeStruct, rv{iVal});
    end
else
    if length(TypeStruct.dims)==2 && ...
            TypeStruct.dims(2)==1
        %catch row vector
        validateattributes(rv, {TypeStruct.type}, {'size', [NaN TypeStruct.dims(2:end)]});
    else
        validateattributes(rv, {TypeStruct.type}, {'size', [TypeStruct.dims(1:end-1) NaN]});
    end
end
end
