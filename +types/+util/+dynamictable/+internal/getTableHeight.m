function [tableHeight, hasEstablishedHeight] = getTableHeight(dynamicTable)
% getTableHeight - Return the inferred row height of a DynamicTable.
%
% This helper returns the effective table height. It differs from
% `getColumnHeight`, which only inspects the stored height of a single
% column object. A table has an established height when it has id data, a
% bound or offset id DataPipe, or at least one data column. A table with no
% id data and no columns returns height 0 with hasEstablishedHeight=false.

    arguments
        dynamicTable
    end

    if ~isempty(dynamicTable.id)
        [tableHeight, hasEstablishedHeight] = ...
            types.util.dynamictable.internal.getColumnHeight(dynamicTable.id);
        if hasEstablishedHeight
            return
        end
    end

    if isempty(dynamicTable.colnames)
        tableHeight = 0;
        hasEstablishedHeight = false;
        return;
    end

    [tableHeight, ~, hasEstablishedHeight] = types.util.dynamictable.internal.getColumnRowHeight( ...
        dynamicTable, dynamicTable.colnames{1});
    tableHeight = unique(tableHeight);
    hasEstablishedHeight = any(hasEstablishedHeight);

    assert(isscalar(tableHeight), ...
        'NWB:DynamicTable:GetRow:InvalidShape', ...
        ['Cannot determine DynamicTable row height because one or more ', ...
         'compound column fields have inconsistent heights.']);
end
