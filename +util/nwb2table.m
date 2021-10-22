function pTable = nwb2table(DynamicTable)
%NWB2TABLE converts from a NWB DynamicTable to a MATLAB table 

%make sure input is dynamic table
validateattributes(DynamicTable,...
    {'types.core.DynamicTable', 'types.hdmf_common.DynamicTable'},...
    {'scalar'});

% get column names
colNames = keys(DynamicTable.vectordata);

% initialize table with id
pTable = table( ...
            DynamicTable.id.data, ...
            'VariableNames', {'id'} ...
            );
for i = 1:length(colNames)
    cn = colNames{i};
    cv = DynamicTable.vectordata.get(cn).data;
    index_name = types.util.dynamictable.getIndex(DynamicTable,cn);
    if ~isempty(index_name)
        index = DynamicTable.vectordata.get(index_name);
        % reformat ragged array
        cv_ragged = cell(length(index.data),1);
        startInd = 1;
        for i = 1:length(index.data)
            endInd = index.data(i);
            cv_ragged{i,1} = cv(startInd:endInd);
            startInd = endInd+1;
        end
        pTable.(cn) = cv_ragged;
    else
        pTable.(cn) = cv;
    end
end