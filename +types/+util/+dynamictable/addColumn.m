function addColumn(dynamicTable, varargin)
% ADDCOLUMN Given a dynamic table and a set of keyword arguments for one or
% more columns, add one or more columns to the dynamic table by providing
% either keywords or a MATLAB table
%
%  ADDCOLUMN(DT,TABLE) append the columns of the MATLAB Table TABLE to the
%  DynamicTable
%
%  ADDCOLUMN(DT,col_name1,col_vector1,...,col_namen,col_vectorn)
%  append specified column names and VectorData to table
%
% This function asserts the following:
% 1) DynamicTable is a valid dynamic table and has the correct
%    properties.
% 2) The height of the columns to be appended matches the height of the
% existing columns

    arguments
        dynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
    end
    arguments (Repeating)
        varargin
    end
    
    assert(nargin > 1, 'NWB:DynamicTable:AddColumn:NoData', ...
        'Not enough arguments');
    
    if isempty(dynamicTable.id)
        types.util.dynamictable.internal.initDynamicTableId(dynamicTable);
    end
    
    assert(~isa(dynamicTable.id.data, 'types.untyped.DataStub'),...
        'NWB:DynamicTable:AddColumn:Uneditable',...
        ['Cannot write to on-file Dynamic Tables without enabling data pipes. '...
        'If this was produced with pynwb, please enable chunking for this table.']);
    
    if istable(varargin{1})
        types.util.dynamictable.addTableColumn(dynamicTable, varargin{:});
    else
        types.util.dynamictable.addVarargColumn(dynamicTable, varargin{:});
    end
end
