function matlabTable = nwbToTable(dynamicTable, index)
%NWBTOTABLE converts from a NWB DynamicTable to a MATLAB table
%
%   MATLABTABLE = NWBTOTABLE(T) converts object T of class types.core.DynamicTable
%   into a MATLAB Table
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

    arguments
        dynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
        index (1,1) logical = true
    end
    
    if isempty(dynamicTable.id)
        matlabTable = table({}, 'VariableNames', [{'id'} dynamicTable.colnames]);
        return;
    end
    
    % initialize table with id column
    if isa(dynamicTable.id.data, 'types.untyped.DataStub')...
            || isa(dynamicTable.id.data, 'types.untyped.DataPipe')
        ids = dynamicTable.id.data.load();
    else
        ids = dynamicTable.id.data;
    end
    matlabTable = table( ...
        ids, ...
        'VariableNames', {'id'} ...
    );
    
    % deal with DynamicTableRegion columns when index is false
    [columns, remainingColumns] = deal(dynamicTable.colnames);
    columnDescriptions = repmat({''}, 1, length(columns));
    
    for iColumn = 1:length(columns)
        columnName = columns{iColumn};
        if isprop(dynamicTable, columnName)
            columnVector = dynamicTable.(columnName);
        elseif isprop(dynamicTable, 'vectorindex') && dynamicTable.vectorindex.isKey(columnName) % Schema version < 2.3.0
            columnVector = dynamicTable.vectorindex.get(columnName);
        else
            columnVector = dynamicTable.vectordata.get(columnName);
        end
        columnDescriptions{iColumn} = columnVector.description;
        if ~index && ...
                (isa(columnVector,'types.hdmf_common.DynamicTableRegion') ||...
                isa(columnVector,'types.core.DynamicTableRegion'))
            rowIndices = columnVector.data;
            referencedTable = columnVector.table.target;
            columnValue = cell(length(rowIndices),1);
            for iRow = 1:length(rowIndices)
                columnValue{iRow,1} = referencedTable.getRow(rowIndices(iRow)+1);
            end
            matlabTable.(columnName) = columnValue;
            remainingColumns = setdiff(remainingColumns, columnName, 'stable');
        else
            % pass
        end
    end
    % append remaining columns to table
    % making the assumption that length of ids reflects table height
    matlabTable = [matlabTable dynamicTable.getRow( ...
        1:length(ids), ...
        'columns', remainingColumns ...
    )];
    
    % Update the columns order to be the same as the original
    if iscolumn(columns); columns = transpose(columns); end
    matlabTable = matlabTable(:, [{'id'}, columns]);
    
    % Add variable descriptions
    matlabTable.Properties.VariableDescriptions = [{''}, columnDescriptions];
end
