function [data_vector, data_index] = create_indexed_column(data, description, table)
%CREATE_INDEXED_COLUMN creates the index and vector NWB objects for storing
%a vector column in an NWB DynamicTable
%
%   [DATA_VECTOR, DATA_INDEX] = CREATE_INDEXED_COLUMN(DATA)
%   expects DATA as a cell array where each cell is all of the data
%   for a row and PATH is the path to the indexed data in the NWB file
%   EXAMPLE: [data_vector, data_index] = util.create_indexed_colum({[1,2,3], [1,2,3,4]})
%   
%   [DATA_VECTOR, DATA_INDEX] = CREATE_INDEXED_COLUMN(DATA, DESCRIPTION)
%   adds the string DESCRIPTION in the description field of the data vector
%   
%   [DYNAMICTABLEREGION, DATA_INDEX] = CREATE_INDEXED_COLUMN(DATA, DESCRIPTION, TABLE)
%   If TABLE is supplied as on ObjectView of an NWB DynamicTable, a
%   DynamicTableRegion is instead output which references this table.
%   DynamicTableRegions can be indexed just like DataVectors

if ~exist('description', 'var') || isempty(description)
    description = 'no description';
end

bounds = NaN(length(data), 1);
for i = 1:length(data)
    bounds(i) = length(data{i});
end
bounds = uint64(cumsum(bounds));

data = cell2mat(data)';

if exist('table', 'var')
    data_vector = types.hdmf_common.DynamicTableRegion( ...
        'table', types.untyped.ObjectView(table), ...
        'description', description, ...
        'data', data ...
    );
else
    data_vector = types.hdmf_common.VectorData( ...
        'data', data, ...
        'description', description ...
    );
end

ov = types.untyped.ObjectView(data_vector);
data_index = types.hdmf_common.VectorIndex( ...
    'data', bounds, ...
    'target', ov, ...
    'description', 'indexes data' ...
);


