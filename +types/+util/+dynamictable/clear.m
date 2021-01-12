function clear(DynamicTable)
%CLEAR Given a valid DynamicTable object, clears all rows and type
%   information in the table.
validateattributes(DynamicTable, {'types.hdmf_common.DynamicTable'}, {'scalar'});
DynamicTable.id = types.hdmf_common.ElementIdentifiers();

DynamicTable.vectordata = types.untyped.Set(@(nm, val)types.util.checkConstraint(...
    'vectordata', nm, struct(), {'types.hdmf_common.VectorData'}, val));
DynamicTable.vectorindex = types.untyped.Set(@(nm, val)types.util.checkConstraint(...
    'vectorindex', nm, struct(), {'types.hdmf_common.VectorIndex'}, val));
end