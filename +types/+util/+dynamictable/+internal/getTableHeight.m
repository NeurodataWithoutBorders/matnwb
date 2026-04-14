function tableHeight = getTableHeight(dynamicTable)
% getTableHeight - Return the inferred row height of a DynamicTable.
%
% This helper returns the effective table height. It differs from
% `getColumnHeight`, which only inspects the stored height of a single
% column object.

    arguments
        dynamicTable
    end

    if ~isempty(dynamicTable.id)
        tableHeight = types.util.dynamictable.internal.getColumnHeight(dynamicTable.id);
        return;
    end

    if isempty(dynamicTable.colnames)
        tableHeight = 0;
        return;
    end

    tableHeight = types.util.dynamictable.internal.getColumnRowHeight( ...
        dynamicTable, dynamicTable.colnames{1});
end
