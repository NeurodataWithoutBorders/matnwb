function addVarargColumn(DynamicTable, varargin)

%check proper argument/value inputs and parse
[newVectorData, ~] = types.util.parseConstrained(DynamicTable,'vectordata', 'types.hdmf_common.VectorData', varargin{:});

newColNames = DynamicTable.validate_colnames({varargin{1:2:end}});
% get current table height - assume id length reflects table height
if ~isempty(DynamicTable.colnames)
    tableHeight = length(DynamicTable.id.data);
end

for i = 1:length(newColNames)
    new_cn = newColNames{i};
    new_cv = newVectorData.get(new_cn);
    % check height match before adding column
    if ~isempty(DynamicTable.colnames)
        indexName = getIndexInSet(newVectorData,new_cn);
        if isempty(indexName)
            assert(height(new_cv.data) == tableHeight,...
                'NWB:DynamicTable:AddColumn:MissingRows',...
                'New column length must match length of existing columns ') 
        else
            assert(height(newVectorData.get(indexName).data) == tableHeight,...
                'NWB:DynamicTable:AddColumn:MissingRows',...
                'New column length must match length of existing columns ') 
        end
    end
    if ~isa(new_cv, 'types.hdmf_common.VectorIndex')
        DynamicTable.colnames{end+1} = new_cn;
    end
    DynamicTable.vectordata.set(new_cn, new_cv);   
end
end

function indexName = getIndexInSet(inputSet, inputName)
    % wrap input set with an empty dynamic table
    T = types.hdmf_common.DynamicTable();
    T.vectordata = inputSet;
    % use dynamic table function to get index name
    indexName = types.util.dynamictable.getIndex(T, inputName);
end

