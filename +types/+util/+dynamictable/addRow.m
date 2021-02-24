function addRow(DynamicTable, varargin)
% ADDROW Given a dynamic table and a set of keyword arguments for the row,
% add a single row to the dynamic table if using keywords, or multiple rows
% if using a table.
%
%  ADDROW(DT,table) append the MATLAB table to the DynamicTable
%
%  ADDROW(DT,col1,val1,col2,val2,...,coln,valn) append a single row
%  to the DynamicTable
%
%  ADDROW(DT,___,Name,Value) specify either 'id' or 'tablepath'
%
% This function asserts the following:
% 1) DynamicTable is a valid dynamic table and has the correct
%    properties.
% 2) The given keyword argument names match one of those ALREADY specified
%    by the DynamicTable (that is, colnames MUST be filled out).
% 3) If the dynamic table is non-empty, the types of the column value MUST
%    match the keyword value.
% 4) All horizontal data must match the width of the rest of the rows.
%    Variable length strings should use cell arrays each row.
% 5) The type of the data cannot be a cell array of numeric values if using
%    keyword arguments. For table appending mode, this is how ragged arrays
%    are represented.
% 6) Ragged arrays (that is, rows containing more than one sub-row) require
%    an extra parameter called `tablepath` which indicates where in the NWB
%    file the table is.

validateattributes(DynamicTable, {'types.hdmf_common.DynamicTable'}, {'scalar'});
assert(~isempty(DynamicTable.colnames),...
    'MatNWB:DynamicTable:AddRow:NoColumns',...
    ['The `colnames` property of the Dynamic Table needs to be populated with a cell array '...
    'of column names before being able to add row data.']);
assert(nargin > 2, 'MatNWB:DynamicTable:AddRow:NoData',...
    'Not enough arguments');

if isempty(DynamicTable.id)
    DynamicTable.id = types.hdmf_common.ElementIdentifiers();
end

assert(~isa(DynamicTable.id.data, 'types.untyped.DataStub'),...
    'MatNWB:DynamicTable:AddRow:Uneditable',...
    ['Cannot write to on-file Dynamic Tables without enabling data pipes. '...
    'If this was produced with pynwb, please enable chunking for this table.']);

if istable(varargin{1})
    types.util.dynamictable.addTableRow(DynamicTable, varargin{:}); 
else
    types.util.dynamictable.addVarargRow(DynamicTable, varargin{:});
end
end





