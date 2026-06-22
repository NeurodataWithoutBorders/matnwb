function [tableHeight, hasEstablishedHeight] = getTableHeight(dynamicTable)

    arguments
        dynamicTable {matnwb.common.validation.mustBeDynamicTable}
    end

    if ~isempty(dynamicTable.id)
        [tableHeight, hasEstablishedHeight] = getIdHeightInfo(dynamicTable.id);
        if hasEstablishedHeight
            return
        end
    end

    if isempty(dynamicTable.colnames)
        tableHeight = 0;
        hasEstablishedHeight = false;
        return
    end

    tableHeight = types.util.dynamictable.internal.getColumnRowHeight( ...
        dynamicTable, dynamicTable.colnames{1});
    tableHeight = unique(tableHeight);

    assert(isscalar(tableHeight), ...
        'NWB:AlignedDynamicTable:GetTableHeightInfo:InvalidShape', ...
        ['Cannot determine DynamicTable row height because one or more ', ...
        'compound column fields have inconsistent heights.']);

    hasEstablishedHeight = true;
end

function [idHeight, hasEstablishedHeight] = getIdHeightInfo(elementIdentifiers)
    idData = elementIdentifiers.data;

    if isa(idData, 'types.untyped.DataStub')
        idHeight = idData.dims(end);
        hasEstablishedHeight = true;
    elseif isa(idData, 'types.untyped.DataPipe')
        [idHeight, hasEstablishedHeight] = getDataPipeHeightInfo(idData);
    elseif isempty(idData)
        idHeight = 0;
        hasEstablishedHeight = false;
    else
        idHeight = types.util.dynamictable.internal.getColumnHeight(elementIdentifiers);
        hasEstablishedHeight = true;
    end
end

function [height, hasEstablishedHeight] = getDataPipeHeightInfo(dataPipe)
    if dataPipe.isBound
        dataSize = size(dataPipe);
        height = dataSize(end);
        hasEstablishedHeight = true;
        return
    end

    if dataPipe.offset > 0
        height = dataPipe.offset;
        hasEstablishedHeight = true;
        return
    end

    height = types.util.dynamictable.internal.getColumnHeight( ...
        types.hdmf_common.ElementIdentifiers('data', dataPipe));
    hasEstablishedHeight = height > 0;
end
