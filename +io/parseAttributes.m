function [args, typename] = parseAttributes(attr_info)
%typename is the type of name if it exists.  Empty string otherwise
%args is a containers.Map of all valid attributes
args = containers.Map;
typename = '';
type = struct('namespace', '', 'name', '');
for i=1:length(attr_info)
    ai = attr_info(i);
    if strcmp(ai.Name, 'neurodata_type')
        type.name = ai.Value{1};
    elseif strcmp(ai.Name, 'namespace')
        type.namespace = ai.Value{1};
    elseif strcmp(ai.Datatype, 'H5T_STRING')
       args(ai.Name) = ai.Value{1}; 
    else
       args(ai.Name) = ai.Value;
    end
end
if ~isempty(type.namespace) && ~isempty(type.name)
    typename = ['types.' type.namespace '.' type.name];
end
end