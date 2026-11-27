classdef TableStubWithColumnTypes < handle
% TableStubWithColumnTypes - Test stub that lists the class of two columns.
%   Stands in for a generated DynamicTable class, which lists the class of
%   its schema-typed columns in the private constant
%   DeclaredSchemaColumnTypes.

    properties (Constant, Access = private)
        DeclaredSchemaColumnTypes = struct( ...
            'parentColumn', 'parent.ColumnClass', ...
            'sharedColumn', 'parent.SharedColumnClass');
    end
end
