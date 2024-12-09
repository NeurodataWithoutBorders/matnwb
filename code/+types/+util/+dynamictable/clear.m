function clear(DynamicTable)
%CLEAR Given a valid DynamicTable object, clears all rows and type
%   information in the table.
validateattributes(DynamicTable, {'types.hdmf_common.DynamicTable', 'types.core.DynamicTable'}, {'scalar'});

if isa(DynamicTable, 'types.core.DynamicTable') % Schema version <2.2.0
    elementIdentifierClass = @types.core.ElementIdentifiers;
    vectorDataClassName = 'types.core.VectorData';
    vectorIndexClassName = 'types.core.VectorIndex';
else
    elementIdentifierClass = @types.hdmf_common.ElementIdentifiers;
    vectorDataClassName = 'types.hdmf_common.VectorData';
    vectorIndexClassName = 'types.hdmf_common.VectorIndex';
end
    
DynamicTable.id = elementIdentifierClass();
DynamicTable.vectordata = types.untyped.Set(@(nm, val)types.util.checkConstraint(...
    'vectordata', nm, struct(), {vectorDataClassName}, val));
if isprop(DynamicTable, 'vectorindex') % Schema version <2.3.0
    DynamicTable.vectorindex = types.untyped.Set(@(nm, val)types.util.checkConstraint(...
        'vectorindex', nm, struct(), {vectorIndexClassName}, val));
end
end
