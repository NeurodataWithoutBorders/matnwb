function clear(dynamicTable)
%CLEAR Given a valid DynamicTable object, clears all rows and type
%   information in the table.
    arguments
        dynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
    end
    
    if isa(dynamicTable, 'types.core.DynamicTable') % Schema version <2.2.0
        elementIdentifierClass = @types.core.ElementIdentifiers;
        vectorDataClassName = 'types.core.VectorData';
        vectorIndexClassName = 'types.core.VectorIndex';
    else
        elementIdentifierClass = @types.hdmf_common.ElementIdentifiers;
        vectorDataClassName = 'types.hdmf_common.VectorData';
        vectorIndexClassName = 'types.hdmf_common.VectorIndex';
    end
    
    dynamicTable.id = elementIdentifierClass();
    dynamicTable.vectordata = types.untyped.Set(@(nm, val)types.util.checkConstraint(...
        'vectordata', nm, struct(), {vectorDataClassName}, val));
    if isprop(dynamicTable, 'vectorindex') % Schema version <2.3.0
        dynamicTable.vectorindex = types.untyped.Set(@(nm, val)types.util.checkConstraint(...
            'vectorindex', nm, struct(), {vectorIndexClassName}, val));
    end
end
