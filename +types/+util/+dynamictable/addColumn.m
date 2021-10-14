function addColumn(DynamicTable, varargin)

validateattributes(DynamicTable,...
    {'types.core.DynamicTable', 'types.hdmf_common.DynamicTable'},...
    {'scalar'});

assert(nargin > 1, 'NWB:DynamicTable:AddColumn:NoData', 'Not enough arguments');

if isempty(DynamicTable.id)
    if 8 == exist('types.hdmf_common.ElementIdentifiers', 'class')
        DynamicTable.id = types.hdmf_common.ElementIdentifiers();
    else % legacy Element Identifiers
        DynamicTable.id = types.core.ElementIdentifiers();
    end
end

assert(~isa(DynamicTable.id.data, 'types.untyped.DataStub'),...
    'NWB:DynamicTable:AddColumn:Uneditable',...
    ['Cannot write to on-file Dynamic Tables without enabling data pipes. '...
    'If this was produced with pynwb, please enable chunking for this table.']);

types.util.dynamictable.addVarargColumn(DynamicTable, varargin{:});
