function initDynamicTableId(dynamicTable, tableHeight)
% Initialize ElementIdentifiers (0-indexed) for a dynamic table.
%
%   This utility method uses the correct namespace for ElementIdentifiers,
%   supporting older NWB versions where ElementIdentifiers were part of the
%   core namespace.
%
%   If the table already has an id object, this function only writes ids
%   when the existing id data is empty or an unbound DataPipe with zero
%   offset. Existing file-backed, non-empty, or already-appended id data is
%   left untouched and reported as an error.

    arguments
        dynamicTable
        tableHeight = []
    end

    idData = createIdData(tableHeight);

    if ~isempty(dynamicTable.id)
        initializeExistingId(dynamicTable, idData)
        return
    end

    if exist('types.hdmf_common.ElementIdentifiers', 'class') == 8
        dynamicTable.id = types.hdmf_common.ElementIdentifiers('data', idData);
    else % legacy ElementIdentifiers
        dynamicTable.id = types.core.ElementIdentifiers('data', idData);
    end
end

function idData = createIdData(tableHeight)
    if isempty(tableHeight)
        idData = [];
    else
        validateattributes(tableHeight, {'numeric'}, ...
            {'scalar', 'integer', 'nonnegative'});
        idData = int64(0:tableHeight-1).';
    end
end

function initializeExistingId(dynamicTable, idData)
    existingIdData = dynamicTable.id.data;

    if isa(existingIdData, 'types.untyped.DataPipe') && ~existingIdData.isBound
        if existingIdData.offset > 0
            error('NWB:DynamicTable:CannotInitializeId', ...
                ['Cannot initialize ids for table `%s` because its id DataPipe ', ...
                'already has an offset of %d.'], class(dynamicTable), existingIdData.offset)
        end

        if ~isempty(idData)
            existingIdData.append(idData)
        end
    elseif isempty(existingIdData)
        dynamicTable.id.data = idData;
    else
        error('NWB:DynamicTable:CannotInitializeId', ...
            ['Cannot initialize ids for table `%s` because its id dataset ', ...
            'already has file-backed or non-empty data.'], class(dynamicTable))
    end
end
