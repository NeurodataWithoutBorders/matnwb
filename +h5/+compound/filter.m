function Data = filter(Data)
import h5.dataset.CompoundDataset;

if isstruct(Data)
    Data = filter_struct(Data);
elseif isa(data, 'containers.Map')
    Data = filter_map(Data);
elseif istable(data)
    Data = filter_table(Data);
else
    error('NWB:H5:Compound:InvalidArguments',...
        'Must write either a struct, containers.Map, or a table');
end
end

function Data = filter_struct(Data)
columnNames = fieldnames(Data(1));
if ~isscalar(Data)
    ScalarData = struct();
    
    for i = 1:length(columnNames)
        name = columnNames{i};
        ScalarData.(name) = [Data.(name)];
    end
    Data = ScalarData;
end

for i = 1:length(columnNames)
    name = columnNames{i};
    
end
end

function Data = filter_map(Map)
names = Map.keys();
data = Map.values(names);

Data = struct();
for i = 1:length(names)
    Data.(misc.str2validName(names{i})) = data{i};
end
Data = filter_struct(Data);
end

function Data = filter_table(Table)
Data = filter_struct(table2struct(Table));
end