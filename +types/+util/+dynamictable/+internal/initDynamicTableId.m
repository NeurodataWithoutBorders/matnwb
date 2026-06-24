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

    if isempty(tableHeight)
        idData = [];
    else
        idData = int64(0:tableHeight-1).';
    end

    if isempty(dynamicTable.id)
        if exist('types.hdmf_common.ElementIdentifiers', 'class') == 8
            dynamicTable.id = types.hdmf_common.ElementIdentifiers('data', idData);
        else % legacy ElementIdentifiers
            dynamicTable.id = types.core.ElementIdentifiers('data', idData);
        end
    elseif isempty(dynamicTable.id.data)
        dynamicTable.id.data = idData;
    elseif isa(dynamicTable.id.data, 'types.untyped.DataPipe') && ~dynamicTable.id.data.isBound
        idDataPipe = dynamicTable.id.data;
        assert(idDataPipe.offset == 0 && isempty(idDataPipe.internal.data), ...
            'NWB:DynamicTable:CannotInitializeId', ...
            ['Cannot initialize ids for table `%s` because its id DataPipe ', ...
            'already has queued data or a nonzero offset.'], class(dynamicTable))

        if ~isempty(idData)
            idDataPipe.append(idData)
        end
    end
end
