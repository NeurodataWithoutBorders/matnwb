function addRow(DynamicTable, varargin)
%ADDROW Given a dynamic table and a set of keyword arguments for the row,
% add a row to the dynamic table if possible.
% This function asserts the following:
% 1) DynamicTable is a valid dynamic table and has the correct
%    properties.
% 2) varargin is a set of keyword arguments (in MATLAB, this is a character
%    array indicating name and a value indicating the row value).
% 3) The given keyword argument names match one of those ALREADY specified
%    by the DynamicTable (that is, colnames MUST be filled out).
% 4) If the dynamic table is non-empty, the types of the column value MUST
%    match the keyword value.
% 5) All horizontal data must match the width of the rest of the rows.
%    Variable length strings should use cell arrays each row.
% 6) The type of the data cannot be a cell array.

assert(isa(DynamicTable, 'types.hdmf_common.DynamicTable') && isscalar(DynamicTable),...
    'MatNWB:DynamicTable:AddRow:InvalidType',...
    'Must be a `types.hdmf_common.DynamicTable`');
assert(~isempty(DynamicTable.colnames),...
    'MatNWB:DynamicTable:AddRow:NoColumns',...
    ['The `colnames` property of the Dynamic Table needs to be populated with a cell array '...
    'of column names before being able to add row data.']);
p = inputParser();
p.KeepUnmatched = true;
p.StructExpand = false;
for i = 1:length(DynamicTable.colnames)
    addParameter(p, [], @(x)~isempty(x)); % that is, these are required.
end
parse(p, varargin);

assert(isempty(p.Unmatched),...
    'MatNWB:DynamicTable:AddRow:InvalidColumns',...
    'Invalid column name(s) { %s }', strjoin(fieldnames(p.Unmatched), ', '));
assert(~isa(DynamicTable.id, 'types.untyped.DataStub'),...
    'MatNWB:DynamicTable:AddRow:Uneditable',...
    ['Cannot write to on-file Dynamic Tables without enabling data pipes. '...
    'If this was produced with pynwb, please enable chunking for this table.']);
rowNames = fieldnames(p.Results);
if isempty(DynamicTable.id)
    DynamicTable.id = types.hdmf_common.ElementIdentifiers();
end

% check if types of the table actually exist yet.
% if table exists, then build a map of name to type and their dimensions.
TypeMap = constructTypeMap(DynamicTable);
for i = 1:length(rowNames)
    rn = rowNames{i};
    rv = p.Results.(rn);
    
    TypeStruct = TypeMap(rn);
    if isKey(TypeMap, rn)
        validateattributes(rv, {TypeStruct.type}, {'size', [NaN TypeStruct.dims(2:end)]});
    end
    indexName = [rn '_index'];
end

if isa(DynamicTable.id.data, 'types.untyped.DataPipe')
else
end
end

function TypeMap = constructTypeMap(DynamicTable)
TypeMap = containers.Map;
if isempty(DynamicTable.id.data)
    return;
end
TypeStruct = struct('type', '', 'dims', [0, 0]);
for i = length(DynamicTable.colnames)
    colnm = DynamicTable.colnames{i};
    colVecData = DynamicTable.vectordata.get(colnm);
    if isa(colVecData.data, 'types.untyped.DataPipe')
        colval = colVecData.data.load(1);
    else
        colval = colVecData.data(1);
    end
    TypeStruct.type = class(colval);
    
    if isa(colVecData.data, 'types.untyped.DataPipe')
        TypeStruct.dims = size(colVecData.data.internal);
    else
        TypeStruct.dims = size(colVecData.data);
    end
    TypeMap(colnm) = TypeStruct;
end
end

