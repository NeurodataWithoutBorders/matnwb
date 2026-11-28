classdef (Abstract) ExpandableTableColumn
% ExpandableTableColumn - Data for a DynamicTable column that is stored as more than one object.
%
% An ExpandableTableColumn holds the data of one DynamicTable column whose
% stored form is the column itself plus other objects, such as the
% VectorIndex columns of a ragged array column. It is passed to a
% DynamicTable constructor or to addColumn under the column's name. The
% table expands it into the objects that toNameValuePairs returns and
% stores those, not the ExpandableTableColumn, so a table read from a file
% holds those objects.
%
% Subclasses implement toNameValuePairs.
%
% See also:
%   types.untyped.RaggedArrayColumn,
%   types.util.dynamictable.expandTableColumns

    methods (Abstract)
        % toNameValuePairs - Return the stored objects of the column as name-value pairs.
        %
        % Syntax:
        %  nameValuePairs = column.toNameValuePairs(columnName) returns a
        %  1-by-2N cell array {columnName, columnObject, name2, object2, ...}.
        %  The first pair is the column itself, and the other pairs are the
        %  objects it is stored with.
        nameValuePairs = toNameValuePairs(obj, columnName)
    end
end
