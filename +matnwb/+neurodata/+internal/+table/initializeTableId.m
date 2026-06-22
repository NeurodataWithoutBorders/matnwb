function initializeTableId(dynamicTable, tableHeight)

    arguments
        dynamicTable {matnwb.common.validation.mustBeDynamicTable}
        tableHeight (1,1) {mustBeNonnegative, mustBeInteger}
    end

    if isempty(dynamicTable.id)
        types.util.dynamictable.internal.initDynamicTableId(dynamicTable, tableHeight);
        return
    end

    idData = dynamicTable.id.data;
    newIdData = int64(0:tableHeight-1).';

    if isa(idData, 'types.untyped.DataPipe') && ~idData.isBound
        if idData.offset > 0
            error('NWB:AlignedDynamicTable:CannotInitializeId', ...
                ['Cannot initialize ids for table `%s` because its id DataPipe ', ...
                'already has an offset of %d.'], class(dynamicTable), idData.offset)
        end

        if tableHeight > 0
            idData.append(newIdData)
        end
    elseif isempty(idData)
        dynamicTable.id.data = newIdData;
    else
        error('NWB:AlignedDynamicTable:CannotInitializeId', ...
            ['Cannot initialize ids for table `%s` because its id dataset ', ...
            'already has file-backed or non-empty data.'], class(dynamicTable))
    end
end
