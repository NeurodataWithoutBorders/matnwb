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
% initialize table with id
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
for i = 1:length(DynamicTable.colnames)
    cn = DynamicTable.colnames{i};
    if ~index && isa(DynamicTable.vectordata.get(cn),'types.hdmf_common.DynamicTableRegion')
        row_idxs = DynamicTable.vectordata.get(cn).data;
        ref_table = DynamicTable.vectordata.get(cn).table.target;
        cv = cell(length(row_idxs),1);
        for r = 1:length(row_idxs)
            cv{r,1} = ref_table.getRow(row_idxs(r)+1);
        end
    else
        cv = DynamicTable.vectordata.get(cn).data;
    end
    index_name = types.util.dynamictable.getIndex(DynamicTable,cn);
    if ~isempty(index_name)
        index = DynamicTable.vectordata.get(index_name);
        % reformat ragged array
        cv_ragged = cell(length(index.data),1);
        startInd = 1;
        for i = 1:length(index.data)
            endInd = index.data(i);
            cv_ragged{i,1} = cv(startInd:endInd);
            startInd = endInd+1;
        end
        pTable.(cn) = cv_ragged;
    else
        pTable.(cn) = cv;
    end
end
end
