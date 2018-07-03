function [args, typename] = parseAttributes(alist)
%typename is the type of name if it exists.  Empty string otherwise
%args is a containers.Map of all valid attributes
args = containers.Map;
typename = '';
type = struct('namespace', '', 'name', '');
for i=1:length(alist)
    attr = alist(i);
    if strcmp(attr.Name, 'neurodata_type')
        if iscellstr(attr.Value)
            type.name = attr.Value{1};
        else
            type.name = attr.Value;
        end
    elseif strcmp(attr.Name, 'namespace')
        if iscellstr(attr.Value)
            type.namespace = attr.Value{1};
        else
            type.namespace = attr.Value;
        end
    elseif isscalar(attr.Value) && iscellstr(attr.Value)
        args(attr.Name) = attr.Value{1};
    else
        args(attr.Name) = attr.Value;
    end
end
if ~isempty(type.namespace) && ~isempty(type.name)
    typename = ['types.' type.namespace '.' type.name];
end
end