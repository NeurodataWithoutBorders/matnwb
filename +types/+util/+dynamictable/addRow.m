function addRow(DynamicTable, varargin)
%ADDROW Given a dynamic table and a set of keyword arguments for the row,
% add a single row to the dynamic table if possible.
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
%    an extra parameter called `tablepath` which indicates where in the NWB
%    file the table is.

validateattributes(DynamicTable, {'types.hdmf_common.DynamicTable'}, {'scalar'});
assert(~isempty(DynamicTable.colnames),...
    'MatNWB:DynamicTable:AddRow:NoColumns',...
    ['The `colnames` property of the Dynamic Table needs to be populated with a cell array '...
    'of column names before being able to add row data.']);
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

if isempty(DynamicTable.id)
    DynamicTable.id = types.hdmf_common.ElementIdentifiers();
end
assert(~isa(DynamicTable.id.data, 'types.untyped.DataStub'),...
    'MatNWB:DynamicTable:AddRow:Uneditable',...
    ['Cannot write to on-file Dynamic Tables without enabling data pipes. '...
    'If this was produced with pynwb, please enable chunking for this table.']);
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
    if isempty(vecIndName) && size(rv, 1) > 1
        assert(~isempty(p.Results.tablepath),...
            'MatNWB:DynamicTable:AddRow:MissingTablePath',...
            ['addRow cannot create ragged arrays without a full HDF5 path to the Dynamic Table. '...
            'Please either add the full expected HDF5 path under the keyword argument `tablepath` '...
            'or call addRow with row data only.']);
        vecIndName = [rn '_index']; % arbitrary convention of appending '_index' to data column names
        if endsWith(p.Results.tablepath, '/')
            tablePath = p.Results.tablepath;
        else
            tablePath = [p.Results.tablepath '/'];
        end
        vecTarget = types.untyped.ObjectView([tablePath rn]);
        oldDataHeight = 0;
        if isKey(DynamicTable.vectordata, rn) || isprop(DynamicTable, rn)
            if isprop(DynamicTable, rn)
                VecData = DynamicTable.(rn);
            else
                VecData = DynamicTable.vectordata.get(rn);
            end
            if isa(VecData.data, 'types.untyped.DataPipe')
                oldDataHeight = VecData.data.offset;
            else
                oldDataHeight = size(VecData.data, 1);
            end
        end
        
        % we presume that if data already existed in the vectordata, then
        % it was never a ragged array and thus its elements corresponded
        % directly to each row index.
        VecIndex = types.hdmf_common.VectorIndex(...
            'target', vecTarget,...
            'data', [0:(oldDataHeight-1)] .'); %#ok<NBRAK>
        if isprop(DynamicTable, vecIndName)
            DynamicTable.(vecIndName) = VecIndex;
        else
            DynamicTable.vectorindex.set(vecIndName, VecIndex);
        end 
    end
    appendData(DynamicTable, rn, rv, vecIndName);
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

function TypeMap = constructTypeMap(DynamicTable)
TypeMap = containers.Map;
if isempty(DynamicTable.id.data)...
        || (isa(DynamicTable.id.data, 'types.untyped.DataPipe')...
            && 0 == DynamicTable.id.data.offset)
    return;
end
TypeStruct = struct('type', '', 'dims', [0, 0]);
for i = length(DynamicTable.colnames)
    colnm = DynamicTable.colnames{i};
    if isprop(DynamicTable, colnm)
        colVecData = DynamicTable.(colnm);
    else
        colVecData = DynamicTable.vectordata.get(colnm);
    end
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

% Don't set the data until after indices are updated.
VecData = types.hdmf_common.VectorData(...
    'description', sprintf('AUTOGENERATED description for column `%s`', column),...
    'data', []);
if isprop(DynamicTable, column)
    if isempty(DynamicTable.(column))
        DynamicTable.(column) = VecData;
    end
    VecData = DynamicTable.(column);
elseif isKey(DynamicTable.vectordata, column)
    VecData = DynamicTable.vectordata.get(column);
else
    DynamicTable.vectordata.set(column, VecData);
end

if ~isempty(index)
    if isa(VecData.data, 'types.untyped.DataPipe')
        raggedIndex = VecData.data.offset;
    else
        raggedIndex = size(VecData.data, 1);
    end
    
    if isprop(DynamicTable, index)
        VecInd = DynamicTable.(index);
    else
        VecInd = DynamicTable.vectorindex.get(index);
    end
    if isa(VecInd.data, 'types.untyped.DataPipe')
        VecInd.data.append(raggedIndex);
    else
        VecInd.data = [VecInd.data; raggedIndex];
    end
end

if isa(VecData.data, 'types.untyped.DataPipe')
    VecData.data.append(data);
else
    VecData.data = [VecData.data; data];
end
end
