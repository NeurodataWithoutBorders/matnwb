function addTableColumn(DynamicTable, subTable)

newColNames = DynamicTable.validate_colnames(subTable.Properties.VariableNames);

% get current table height - assume id length reflects table height
if ~isempty(DynamicTable.colnames)
    tableHeight = length(DynamicTable.id.data);
end

for i = 1:length(newColNames)
    new_cn = newColNames{i};
    new_cv = types.hdmf_common.VectorData( ...
        'description', 'new column', ...
        'data', subTable.(new_cn) ...
        );
    % check height match before adding column
    if ~isempty(DynamicTable.colnames)
        assert(height(new_cv.data) == tableHeight,...
            'NWB:DynamicTable:AddColumn:MissingRows',...
            'New column length must match length of existing columns ') 
    end
    DynamicTable.colnames{end+1} = new_cn;
    DynamicTable.vectordata.set(new_cn, new_cv);   
end
