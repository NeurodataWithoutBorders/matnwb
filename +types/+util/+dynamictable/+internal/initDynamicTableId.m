function initDynamicTableId(dynamicTable, tableHeight)
% Initialize ElementIdentifiers (0-indexed) for a dynamic table.
%
%   This utility method uses the correct namespace for ElementIdentifiers,
%   supporting older NWB versions where ElementIdentifiers were part of the
%   core namespace.

    arguments
        dynamicTable
        tableHeight = []
    end

    if ~isempty(tableHeight)
        idData = int64(1:tableHeight) .' - 1;
    else
        idData = [];
    end
    
    if exist('types.hdmf_common.ElementIdentifiers', 'class') == 8
        dynamicTable.id = types.hdmf_common.ElementIdentifiers('data', idData);
    else % legacy ElementIdentifiers
        dynamicTable.id = types.core.ElementIdentifiers('data', idData);
    end
end
