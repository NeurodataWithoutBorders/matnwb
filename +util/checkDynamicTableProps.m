function checkDynamicTableProps(DynamicTable)
% Check the properties the given DynamicTable Object
% Specifically, the function ensures two things.
% 1) Length of all columns in the dynamic table are the same.
% 2) All rows have a corresponding id. If none, exist it creates them.

% keep track of last non-ragged column index; to prevent looping over array twice
lastStraigthCol = 0;
lens = zeros(length(DynamicTable.colnames),1);
for c = 1:length(DynamicTable.colnames)
    colName = DynamicTable.colnames{c};
    % ignore columns that have an index (i.e. ragged), length will be unmatched
    if isempty(types.util.dynamictable.getIndex(DynamicTable, colName))
        if isprop(DynamicTable, colName)
            lens(c) = length(DynamicTable.(colName));
        else
            if ~isempty(keys(DynamicTable.vectordata))
                lens(c) = length(DynamicTable.vectordata.get(colName).data);
            end
        end
        if lastStraigthCol > 0
            assert(lens(c)==lens(lastStraigthCol), ...
                'NWB:DynamicTable', ...
                'All columns must be the same length.' ...
                );
        end
        lastStraigthCol = c;
    end
end

if ~isempty(lens)
    if isempty(DynamicTable.id)
        DynamicTable.id = types.hdmf_common.ElementIdentifiers( ...
            'data', ((1:lens(1))-1)' ...
            );
    else
        assert(lens(1) == length(DynamicTable.id.data), ...
            'NWB:DynamicTable', ...
            'Must provide same number of ids as length of columns.' ...
        );
    end
else
    DynamicTable.id = types.hdmf_common.ElementIdentifiers();
end
