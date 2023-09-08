function addVarargColumn(DynamicTable, columnName, VectorData, VectorIndices)
    validateattributes(columnName, {'char', 'string'}, {'scalartext'} ...
        , 'addVarargColumn', 'columnName');

    columnName = DynamicTable.validate_colnames(convertStringsToChars(columnName));

    validateattributes(VectorData ...
        , {'types.hdmf_common.VectorData', 'types.core.VectorData'}, {'scalar'} ...
        , 'addVarargColumn', 'VectorData');

    if 4 <= nargin
        validateattributes(VectorIndices ...
            , {'types.hdmf_common.VectorIndex', 'types.core.VectorIndex'}, {'vector'} ...
            , 'addVarargColumn', 'VectorIndices');
        validateIndexOrder(VectorIndices, VectorData);
    else
        VectorIndices = [];
    end

    if isempty(VectorIndices)
        columnHeight = getColumnDataHeight(VectorData.data);
    else
        columnHeight = getColumnDataHeight(VectorIndices(end).data);
    end

    if ~isempty(DynamicTable.colnames)
        % get current table height assuming id length is valid. Do not check for empty tables.
        if isempty(DynamicTable.id)
            tableHeight = 0;
        else
            tableHeight = length(DynamicTable.id.data);
        end
        assert(columnHeight == tableHeight ...
            , 'NWB:DynamicTable:AddColumn:MissingRows' ...
            , [ ...
            'Height of column "%s" (with height %d) does not match the pre-existant table height %d. ' ...
            'This function no longer supports nested data objects, please use "addRow" for each ' ...
            'nested object instead.'] ...
            , columnName, columnHeight, tableHeight);
    end

    if isempty(DynamicTable.colnames)
        DynamicTable.colnames = {columnName};
    else
        DynamicTable.colnames{end+1} = columnName;
    end
    addToDynamicTable(DynamicTable, columnName, VectorData);
    for iIndex = 1:length(VectorIndices)
        Index = VectorIndices(iIndex);
        indexName = sprintf('%s%s', columnName, repmat('_index', 1, iIndex));
        addToDynamicTable(DynamicTable, indexName, Index);
    end
end

function addToDynamicTable(DynamicTable, name, Vector)
    if isprop(DynamicTable, name)
        DynamicTable.(name) = Vector;
        return;
    end

    [~, indexClassName] = types.util.getVectorClassName();
    if isa(Vector, indexClassName) && isprop(DynamicTable, 'vectorindex')
        addVector = @(name, I)DynamicTable.vectorindex.set(name, I);
    else
        addVector = @(name, V)DynamicTable.vectordata.set(name, V);
    end
    addVector(name, Vector);
end

function validateIndexOrder(VectorIndices, VectorData)
    isValidationAmbiguous = false;
    for iIndex = 1:length(VectorIndices)
        Index = VectorIndices(iIndex);
        ObjectView = Index.target;

        if 1 == iIndex
            ExpectedTarget = VectorData;
        else
            ExpectedTarget = VectorIndices(iIndex - 1);
        end

        if isempty(ObjectView)
            Index.target = types.untyped.ObjectView(ExpectedTarget);
            continue;
        end

        assert(~isempty(ObjectView) ...
            , 'NWB:DynamicTable:AddColumn:InvalidIndex' ...
            , ['VectorIndex objects must be pointed either to their predecessor VectorIndex or ' ...
            'the provided VectorData object.']);
        Target = ObjectView.target;
        if isempty(Target)
            isValidationAmbiguous = true;
            continue;
        end
        
        assert(ExpectedTarget == Target ...
            , 'NWB:DynamicTable:AddColumn:InvalidIndexTarget' ...
            , [ ...
            'VectorIndices argument must be ordered such that VectorIndices(N) points to ' ...
            'VectorIndices(N-1) and VectorIndices(1) points to VectorData']);
    end
    if isValidationAmbiguous
        warningId = 'NWB:DynamicTable:AddColumn:UnverifiableIndexTarget';
        warning(warningId ...
            , ['Some of the Vector Indices could not have their reference target verified as ' ...
            'they do not contain object targets. If not verified by the user, this may cause ' ...
            'validation errors when added to the DynamicTable object. You can suppress this ' ...
            'warning by running "%1$s" in the commnd window or clicking <a href="matlab:%1$s">here</a>.'] ...
            , sprintf('warning(''off'',''%s'');', warningId));
    end
end

function v = getColumnDataHeight(columnData)
    if ischar(columnData)
        v = size(columnData, 1);
    elseif isa(columnData, 'types.untyped.DataPipe')
        v = columnData.offset;
    elseif isa(columnData, 'types.untyped.DataStub')
        newDims = columnData.dims;
        if isempty(newDims)
            v = 0;
        else
            v = newDims(1);
        end
    else
        v = length(columnData);
    end
end

