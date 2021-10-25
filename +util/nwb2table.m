function pTable = nwb2table(DynamicTable, index)
%NWB2TABLE converts from a NWB DynamicTable to a MATLAB table 
%     Args:
%         DynamicTable: a DynamicTable object
%         index: Boolean indicating whether to return row indices of
%         DynamicTableRegion column. If False, will return nested table
%         with rows of reference table.
%  
%     Returns:
%         pTable: MATLAB table object
%  


%make sure input is dynamic table
validateattributes(DynamicTable,...
    {'types.core.DynamicTable', 'types.hdmf_common.DynamicTable'},...
    {'scalar'});

if nargin < 2
    index = true;
end
% initialize table with id column
if isa(DynamicTable.id.data, 'types.untyped.DataStub')...
        || isa(DynamicTable.id.data, 'types.untyped.DataPipe')
    ids = DynamicTable.id.data.load();
else
    ids = DynamicTable.id.data;
end
pTable = table( ...
            ids, ...
            'VariableNames', {'id'} ...
           );      
% deal with DynamicTableRegion columns when index is false
columns = DynamicTable.colnames;
i = 1;
while i <length(columns)
    cn = DynamicTable.colnames{i};
    if isprop(DynamicTable, cn)
        cv = DynamicTable.(cn);
    elseif isprop(DynamicTable, 'vectorindex') && DynamicTable.vectorindex.isKey(cn) % Schema version < 2.3.0
        cv = DynamicTable.vectorindex.get(cn);
    else
        cv = DynamicTable.vectordata.get(cn);
    end
    if ~index && isa(cv,'types.hdmf_common.DynamicTableRegion')
        row_idxs = cv.data;
        ref_table = cv.table.target;
        cv = cell(length(row_idxs),1);
        for r = 1:length(row_idxs)
            cv{r,1} = ref_table.getRow(row_idxs(r)+1);
        end
        pTable.(cn) = cv;
        columns(i) = [];
    else
        i = i+1;
    end
end
% append remaining columns to table
% making the assumption that length of ids reflects table height
pTable = [pTable DynamicTable.getRow( ...
                            1:length(ids), ...
                            'columns', columns)];

