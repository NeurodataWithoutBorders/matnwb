function addColumn(DynamicTable, varargin)
    % ADDCOLUMN Given a dynamic table and a keyword argument, add a column to the dynamic table.
    %
    %  ADDCOLUMN(DT,NM,VD)
    %  append specified column name NM and non-ragged VectorData VD to DynamicTable DT
    %
    %  ADDCOLUMN(DT,NM, VD, VI) append specified column by col_name NM represented
    %  by multiple VectorIndex references VI ordered in such a way where VI(n) references V(n-1) and
    %  VI(1) references VectorData VD.
    %
    % This function asserts the following:
    % 1) DynamicTable is a valid dynamic table and has the correct
    %    properties.
    % 2) The height of the columns to be appended matches the height of the
    % existing columns

    validateattributes(DynamicTable ...
        , {'types.core.DynamicTable', 'types.hdmf_common.DynamicTable'} ...
        , {'scalar'});

    assert(nargin > 1, 'NWB:DynamicTable:AddColumn:NoData', 'Not enough arguments');

    if isempty(DynamicTable.id)
        if 8 == exist('types.hdmf_common.ElementIdentifiers', 'class')
            DynamicTable.id = types.hdmf_common.ElementIdentifiers();
        else % legacy Element Identifiers
            DynamicTable.id = types.core.ElementIdentifiers();
        end
    end

    assert(~isa(DynamicTable.id.data, 'types.untyped.DataStub') ...
        , 'NWB:DynamicTable:AddColumn:Uneditable' ...
        , [ ...
        'Cannot write to on-file Dynamic Tables without enabling data pipes. '...
        'If this was produced with pynwb, please enable chunking for this table.']);

    assert(~istable(varargin{1}) ...
        , 'NWB:DynamicTable:AddColumn:InvalidArgument' ...
        , [ ...
        'Using MATLAB tables as input to the addColumn DynamicTable method has been deprecated. ' ...
        'Please, use key-value pairs instead.']);
    types.util.dynamictable.addVarargColumn(DynamicTable, varargin{:});
end
