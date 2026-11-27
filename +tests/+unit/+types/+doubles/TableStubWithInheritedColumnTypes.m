classdef TableStubWithInheritedColumnTypes < tests.unit.types.doubles.TableStubWithColumnTypes
% TableStubWithInheritedColumnTypes - Test stub that adds to the column
%   classes of its superclass. It lists one column of its own and lists
%   `sharedColumn` again with a different class.

    properties (Constant, Access = private)
        DeclaredSchemaColumnTypes = struct( ...
            'childColumn', 'child.ColumnClass', ...
            'sharedColumn', 'child.SharedColumnClass');
    end
end
