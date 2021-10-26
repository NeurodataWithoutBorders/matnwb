function checkDynamicTableConfig(DynamicTable)
% checkDynamicTableConfig  Check the configuration of the given DynamicTable object
%
%   checkDynamicTableConfig(DynamicTable)
%   runs without error if the DynamicTable is configured correctly
%
%  A properly configured DynamicTable should meet the following criteria:
%  1) The length of all columns in the dynamic table is the same.
%  2) All rows have a corresponding id. If none exist, this function creates them.

% keep track of last non-ragged column index; to prevent looping over array twice
columns = DynamicTable.colnames;
c = 1;
lastStraigthCol = 0;
lens = zeros(length(columns),1);
while c <= length(columns)
    cn = columns{c};
    % ignore columns that have an index (i.e. ragged), length will be unmatched
    indexName = types.util.dynamictable.getIndex(DynamicTable, cn);
    if isempty(indexName)
        if isprop(DynamicTable, cn)
            cv = DynamicTable.(cn);
            if ~isempty(cv)
                lens(c) = length(cv.data);
            end
        else
            if ~isempty(keys(DynamicTable.vectordata))
                try
                    cv = DynamicTable.vectordata.get(cn);
                catch % catch legacy table instance
                    cv = DynamicTable.vectorindex.get(cn);
                end
                lens(c) = length(cv.data);
            end
        end
        if lastStraigthCol > 0
            assert(lens(c)==lens(lastStraigthCol), ...
                'NWB:DynamicTable', ...
                'All columns must be the same length.' ...
                );
        end
        lastStraigthCol = c;
    else
        if ~any(strcmp(columns,indexName))
            columns{length(columns)+1} = indexName;
            
        end
    end
    c = c+1;
end

if ~isempty(lens)
    if isempty(DynamicTable.id)
        DynamicTable.id = types.hdmf_common.ElementIdentifiers( ...
            'data', int64((1:lens(lastStraigthCol))-1)' ...
        );
    else
        assert(lens(lastStraigthCol) == length(DynamicTable.id.data), ...
            'NWB:DynamicTable', ...
            'Must provide same number of ids as length of columns.' ...
        );
    end
else
    DynamicTable.id = types.hdmf_common.ElementIdentifiers();
end