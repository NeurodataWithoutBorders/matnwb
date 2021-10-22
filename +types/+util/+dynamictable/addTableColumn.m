function addTableColumn(DynamicTable, subTable)

newColNames = DynamicTable.validate_colnames(subTable.Properties.VariableNames);

for i = 1:length(newColNames)
    new_cn = newColNames{i};
    new_cv = sub_table.(new_cn);
    % check that table height matches column height

    DynamicTable.colnames{end+1} = new_cn;
    DynamicTable.vectordata.set(new_cn, new_cv);   
end