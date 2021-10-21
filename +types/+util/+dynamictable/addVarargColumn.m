function addVarargColumn(DynamicTable, varargin)

%check proper argument/value inputs and parse
[newVectorData, ivarargin] = types.util.parseConstrained(DynamicTable,'vectordata', 'types.hdmf_common.VectorData', varargin{:});

newColNames = DynamicTable.validate_colnames({varargin{1:2:end}});


for i = 1:length(newColNames)
    new_cn = newColNames{i};
    new_cv = newVectorData.get(new_cn);
%     %check height before adding column
%     if ~isempty(DynamicTable.colnames) !!! would have to make sure that
%     chosen column is not a ragged column..
%         table_height = height(DynamicTable.vectordata.get(DynamicTable.colnames{1}).data);
%         assert(height(new_cv.data) == table_height,...
%             'NWB:DynamicTable:AddColumn:MissingRows',...
%             'New column length must match length of existing columns ') 
%     end
    if ~isa(new_cv, 'types.hdmf_common.VectorIndex')
        DynamicTable.colnames{end+1} = new_cn;
    end
    DynamicTable.vectordata.set(new_cn, new_cv);   
end