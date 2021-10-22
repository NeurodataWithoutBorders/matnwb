function addVarargColumn(DynamicTable, varargin)

%check proper argument/value inputs and parse
[newVectorData, ~] = types.util.parseConstrained(DynamicTable,'vectordata', 'types.hdmf_common.VectorData', varargin{:});

newColNames = DynamicTable.validate_colnames({varargin{1:2:end}});
% get current table height
if ~isempty(DynamicTable.colnames)
    columnHeight = getColumnsHeight(DynamicTable);
    tableHeight = columnHeight(1);
end

for i = 1:length(newColNames)
    new_cn = newColNames{i};
    new_cv = newVectorData.get(new_cn);
    % check height match before adding column
    if ~isempty(DynamicTable.colnames)
        assert(height(new_cv.data) == tableHeight,...
            'NWB:DynamicTable:AddColumn:MissingRows',...
            'New column length must match length of existing columns ') 
    end
    if ~isa(new_cv, 'types.hdmf_common.VectorIndex')
        DynamicTable.colnames{end+1} = new_cn;
    end
    DynamicTable.vectordata.set(new_cn, new_cv);   
end
end

%scratch
tmpTable = types.hdmf_common.DynamicTable();
tmpTable.vectordata = newVectorData;
ind_name = types.util.dynamictable.getIndex(tmpTable,new_cn);
ind = newVectorData.get(ind_name);



function lens = getColumnsHeight(DynamicTable)   
    columns = keys(DynamicTable.vectordata);
    c = 1;
    while c <= length(columns)
        if ~isempty(types.util.dynamictable.getIndex(DynamicTable,columns{c}))
            columns(c) = [];
        else
            c = c+1;
        end
    end
    lens = zeros(length(columns),1);
    lens_equal = zeros(length(columns),1);
    for c = 1:length(columns)
        lens(c)=length(DynamicTable.vectordata.get(columns{c}).data);
        lens_equal(c) = lens(1)==lens(c);
    end
    assert(all(lens_equal), ...
        'NWB:DynamicTable', ...
        'All existing columns must be the same length.' ...
        );
end



