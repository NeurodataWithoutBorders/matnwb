function nwbtable = table2nwb(T)

%EXAMPLE
%   T = table([.1, 1.5, 2.5]',[1., 2., 3.]',[0,1,0]',...
%       'VariableNames',{'start','stop','condition'});
%   T.Properties.Description = 'my description';
%   T.Properties.UserData = containers.Map('source','my source');
%nwbfile.trials = table2nwb(T)

if ismember('id', T.Properties.VariableNames)
    id = T.id;
else
    id = 0:height(T)-1;
end

nwbtable = types.core.DynamicTable( ...
    'source',T.Properties.UserData('source'),...
    'colnames', T.Properties.VariableNames,...
    'description', T.Properties.Description, ...
    'id', types.core.ElementIdentifiers('data', id));

for col = T
    if ~strcmp(col.Properties.VariableNames{1},'id')
        nwbtable.tablecolumn.set(col.Properties.VariableNames{1}, ...
            types.core.TableColumn('data', col.Variables',...
            'description','my description'));
    end
end