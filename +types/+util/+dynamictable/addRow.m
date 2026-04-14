function addRow(dynamicTable, varargin)
% ADDROW Given a dynamic table and a set of keyword arguments for the row,
% add a single row to the dynamic table if using keywords, or multiple rows
% if using a table.
%
%  ADDROW(DT,table) append the MATLAB table to the DynamicTable
%
%  ADDROW(DT,col1,val1,col2,val2,...,coln,valn) append a single row
%  to the DynamicTable
%
%  ADDROW(DT,___,Name,Value) optional 'id'
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
    
    arguments
        dynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
    end
    arguments (Repeating)
        varargin
    end

    assert(nargin > 1, 'NWB:DynamicTable:AddRow:NoData', ...
        'Not enough arguments');

    assert(~isempty(dynamicTable.colnames),...
        'NWB:DynamicTable:AddRow:NoColumns',...
        ['The `colnames` property of the Dynamic Table needs to be populated '...
        'with a cell array of column names before being able to add row data.']);
    
    types.util.dynamictable.checkConfig(dynamicTable);
    
    assert(~isa(dynamicTable.id.data, 'types.untyped.DataStub'),...
        'NWB:DynamicTable:AddRow:Uneditable',...
        ['Cannot write to on-file Dynamic Tables without enabling data pipes. '...
        'If this was produced with pynwb, please enable chunking for this table.']);
    
    if istable(varargin{1})
        error('NWB:DynamicTable', ...
        ['Using MATLAB tables as input to the addRow DynamicTable method has '...
        'been deprecated. Please, use key-value pairs instead']);
    else
        types.util.dynamictable.addVarargRow(dynamicTable, varargin{:});
    end
end
