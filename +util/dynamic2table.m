function mat_table = dynamic2table(dyntable)
%DYNAMIC2TABLE Converts Dynamic Tables to MATLAB table object
%   Converts types.core.DynamicTable objects to MATLAB table() objects.

assert(isa(dyntable, 'types.core.DynamicTable'),...
    'MATNWB:INVALIDTABLE',...
    'Input argument `dyntable` must be a `types.core.DynamicTable` object (or a descendent of it).');

end

