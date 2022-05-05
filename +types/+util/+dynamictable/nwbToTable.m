function matlabTable = nwbToTable(DynamicTable, index)
%NWBTOTABLE converts from a NWB DynamicTable to a MATLAB table 
%
%   MATLABTABLE = NWBTOTABLE(T) converts object T of class types.core.DynamicTable
%   into a MATLAB Tale
%   
%   MATLABTABLE = NWBTOTABLE(T, INDEX) If INDEX is FALSE, includes rows referenced by a
%   DynamicTableRegion as nested subtables
%
% EXAMPLE 
% MYTABLE = types.hdmf_common.DynamicTable( ...
%     'description','an example table', ...
%     'colnames', {'col1','col2'}, ...
%     'col1', types.hdmf_common.VectorData( ...
%         'description', 'column #1', ...
%         'data', [1;2] ...
%     ), ...
%     'col2',types.hdmf_common.VectorData( ...
%         'description', 'column #2', ...
%         'data', {'a';'b'} ...
%      ), ...
%     'id', types.hdmf_common.ElementIdentifiers('data', [0;1]) ...
% );
% MATLABTABLE = nwb2table(MYTABLE);

%make sure input is dynamic table
validateattributes(DynamicTable,...
    {'types.core.DynamicTable', 'types.hdmf_common.DynamicTable'},...
    {'scalar'});

if nargin < 2
    index = true;
end

if isempty(DynamicTable.id)
    matlabTable = table({}, 'VariableNames', [{'id'} DynamicTable.colnames]);
    return;
end

% initialize table with id column
if isa(DynamicTable.id.data, 'types.untyped.DataStub')...
        || isa(DynamicTable.id.data, 'types.untyped.DataPipe')
    ids = DynamicTable.id.data.load();
else
    ids = DynamicTable.id.data;
end
matlabTable = table( ...
    ids, ...
    'VariableNames', {'id'} ...
);

% deal with DynamicTableRegion columns when index is false
columns = DynamicTable.colnames;
i = 1;
while i < length(columns)
    cn = DynamicTable.colnames{i};
    if isprop(DynamicTable, cn)
        cv = DynamicTable.(cn);
    elseif isprop(DynamicTable, 'vectorindex') && DynamicTable.vectorindex.isKey(cn) % Schema version < 2.3.0
        cv = DynamicTable.vectorindex.get(cn);
    else
        cv = DynamicTable.vectordata.get(cn);
    end
    if ~index && ...
            (isa(cv,'types.hdmf_common.DynamicTableRegion') ||...
            isa(cv,'types.core.DynamicTableRegion'))
        row_idxs = cv.data;
        ref_table = cv.table.target;
        cv = cell(length(row_idxs),1);
        for r = 1:length(row_idxs)
            cv{r,1} = ref_table.getRow(row_idxs(r)+1);
        end
        matlabTable.(cn) = cv;
        columns(i) = [];
    else
        i = i+1;
    end
end
% append remaining columns to table
% making the assumption that length of ids reflects table height
matlabTable = [matlabTable DynamicTable.getRow( ...
    1:length(ids), ...
    'columns', columns ...
)];

