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
% 6) The type of the data cannot be a cell array of numeric values.
% 7) Ragged arrays (that is, rows containing more than one sub-row) require
%    an extra parameter called `tablepath` which 

validateattributes(DynamicTable, {'types.hdmf_common.DynamicTable'}, {'scalar'});
assert(~isempty(DynamicTable.colnames),...
    'MatNWB:DynamicTable:AddRow:NoColumns',...
    ['The `colnames` property of the Dynamic Table needs to be populated with a cell array '...
    'of column names before being able to add row data.']);
p = inputParser();
p.KeepUnmatched = true;
p.StructExpand = false;
addParameter(p, 'tablepath', '', @(x)ischar(x)); % required for ragged arrays.
for i = 1:length(DynamicTable.colnames)
    addParameter(p, DynamicTable.colnames{i}, {}, @(x)~isempty(x)); % that is, these are required.
end
parse(p, varargin{:});

assert(isempty(fieldnames(p.Unmatched)),...
    'MatNWB:DynamicTable:AddRow:InvalidColumns',...
    'Invalid column name(s) { %s }', strjoin(fieldnames(p.Unmatched), ', '));

if isempty(DynamicTable.id)
    DynamicTable.id = types.hdmf_common.ElementIdentifiers();
end
assert(~isa(DynamicTable.id.data, 'types.untyped.DataStub'),...
    'MatNWB:DynamicTable:AddRow:Uneditable',...
    ['Cannot write to on-file Dynamic Tables without enabling data pipes. '...
    'If this was produced with pynwb, please enable chunking for this table.']);
rowNames = fieldnames(p.Results);
rowNames(strcmp(rowNames, 'tablepath')) = [];

% check if types of the table actually exist yet.
% if table exists, then build a map of name to type and their dimensions.
TypeMap = constructTypeMap(DynamicTable);
for i = 1:length(rowNames)
    rn = rowNames{i};
    rv = p.Results.(rn);
    
    if isKey(TypeMap, rn)
        TypeStruct = TypeMap(rn);
        validateattributes(rv, {TypeStruct.type}, {'size', [NaN TypeStruct.dims(2:end)]});
    else
        assert(iscellstr(rv) || ~iscell(rv),...
            'MatNWB:DynamicTable:AddRow:InvalidCellArray',...
            'Cell arrays that are not cell strings are not allowed.');
    end
    
    % instantiate vector index here because it's dependent on the table
    % fullpath.
    vecIndName = types.util.dynamictable.getIndex(DynamicTable, rn);
    if isempty(vecIndName) && size(rv, 1) > 1 % that is, this is now a ragged array
        assert(~isempty(p.Results.tablepath),...
            'MatNWB:DynamicTable:AddRow:MissingTablePath',...
            ['addRow cannot create ragged arrays without a full HDF5 path to the Dynamic Table. '...
            'Please either add the full expected HDF5 path under the keyword argument `tablepath` '...
            'or call addRow with row data only.']);
        vecIndName = [rn '_index']; % just append '_index' by default
        if endsWith(p.Results.tablepath, '/')
            tablePath = p.Results.tablepath;
        else
            tablePath = [p.Results.tablepath '/'];
        end
        vecTarget = types.untyped.ObjectView([tablePath rn]);
        oldDataHeight = 0;
        if isKey(DynamicTable.vectordata, rn)
            VecData = DynamicTable.vectordata.get(rn);
            if isa(VecData.data, 'types.untyped.DataPipe')
                oldDataHeight = VecData.data.offset;
            else
                oldDataHeight = size(VecData.data, 1);
            end
        end
        DynamicTable.vectorindex.set(vecIndName,...
            types.hdmf_common.VectorIndex(...
            'target', vecTarget,...
            'data', [0:(oldDataHeight-1)] .')); %#ok<NBRAK> % populate data with previously non-ragged index range.
    end
    appendData(DynamicTable, rn, rv, vecIndName);
end

% push to id
if isa(DynamicTable.id.data, 'types.untyped.DataPipe')
    DynamicTable.id.data.append(DynamicTable.id.data.offset);
elseif isempty(DynamicTable.id.data)
    DynamicTable.id.data = 0;
else
    DynamicTable.id.data = [DynamicTable.id.data; length(DynamicTable.id.data)];
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
        TypeStruct.dims = colVecData.data.internal.maxSize;
    else
        TypeStruct.dims = size(colVecData.data);
    end
    TypeMap(colnm) = TypeStruct;
end
end

function appendData(DynamicTable, column, data, index)
validateattributes(column, {'char'}, {'scalartext'});
if nargin < 4
    % indicates an index column. Note we assume that the index name is correct.
    % Validation of this index name must occur upstream.
    index = '';
end

if ~isKey(DynamicTable.vectordata, column)
    DynamicTable.vectordata.set(column, types.hdmf_common.VectorData(...
        'description', sprintf('AUTOGENERATED description for column `%s`', column),...
        'data', [])); % Don't set the data until after indices are updated.
end
VecData = DynamicTable.vectordata.get(column);

% Update index if necessary.
if ~isempty(index)
    if isa(VecData.data, 'types.untyped.DataPipe')
        raggedIndex = VecData.data.offset;
    else
        raggedIndex = size(VecData.data, 1);
    end
    
    VecInd = DynamicTable.vectorindex.get(index);
    if isa(VecInd.data, 'types.untyped.DataPipe')
        VecInd.data.append(raggedIndex);
    else
        VecInd.data = [VecInd.data; raggedIndex];
    end
end

% instantiate data
if isa(VecData.data, 'types.untyped.DataPipe')
    VecData.data.append(data);
else
    VecData.data = [VecData.data; data];
end
end
