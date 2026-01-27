function addVarargColumn(DynamicTable, varargin)

%parse inputs
p = inputParser();
p.KeepUnmatched = true;
p.StructExpand = false;
parse(p, varargin{:});
newColNames = DynamicTable.validate_colnames(fieldnames(p.Unmatched));
newVectorData = p.Unmatched;

% Check if any of the new columns already exist in the table
if ~isempty(DynamicTable.colnames)
    existingCols = intersect(newColNames, DynamicTable.colnames);
    assert(isempty(existingCols), ...
        'NWB:DynamicTable:AddColumn:ColumnExists', ...
        'Column(s) { %s } already exist in the table', strjoin(existingCols, ', '));
end

% Check if this is the first column being added (no existing columns and no id data)
isFirstColumn = isempty(DynamicTable.colnames) && ...
    (isempty(DynamicTable.id) || isempty(DynamicTable.id.data));

% get current table height - assume id length reflects table height
if ~isempty(DynamicTable.colnames)
    tableHeight = length(DynamicTable.id.data);
end

% If adding the first column, initialize the id with 0-indexed values
if isFirstColumn && ~isempty(newColNames)
    % Determine the height from the first non-index column
    firstColName = newColNames{1};
    firstColData = newVectorData.(firstColName);
    indexName = getIndexInSet(newVectorData, firstColName);
    if isempty(indexName)
        newTableHeight = matnwb.common.compatibility.height(firstColData.data);
    else
        newTableHeight = matnwb.common.compatibility.height(newVectorData.(indexName).data);
    end
    
    types.util.dynamictable.internal.initDynamicTableId(DynamicTable, newTableHeight);
    tableHeight = newTableHeight;
end

for i = 1:length(newColNames)
    new_cn = newColNames{i};
    new_cv = newVectorData.(new_cn);    
    % check height match before adding column
    if ~isempty(DynamicTable.colnames)
        indexName = getIndexInSet(newVectorData,new_cn);
        if isempty(indexName)
            assert(matnwb.common.compatibility.height(new_cv.data) == tableHeight,...
                'NWB:DynamicTable:AddColumn:MissingRows',...
                'New column length must match length of existing columns ') 
        else
            assert(matnwb.common.compatibility.height(newVectorData.(indexName).data) == tableHeight,...
                'NWB:DynamicTable:AddColumn:MissingRows',...
                'New column length must match length of existing columns ') 
        end
    end
    if 8 == exist('types.hdmf_common.VectorIndex', 'class')
        if ~isa(new_cv, 'types.hdmf_common.VectorIndex')
            DynamicTable.colnames{end+1} = new_cn;
        end
    else %legacy case
        if ~isa(new_cv, 'types.core.VectorIndex')
            DynamicTable.colnames{end+1} = new_cn;
        end
    end
    DynamicTable.vectordata.set(new_cn, new_cv);   
end
end

function indexName = getIndexInSet(inputStruct, inputName)
    % wrap input set with an empty dynamic table
    T = types.hdmf_common.DynamicTable();
    % convert input structure to a set
    columnNames = fieldnames(inputStruct);
    for i = 1:length(columnNames)
        T.vectordata.set(columnNames{i},inputStruct.(columnNames{i}));
    end
    % use dynamic table function to get index name
    indexName = types.util.dynamictable.getIndex(T, inputName);
end

