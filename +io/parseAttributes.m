function [args, type] = parseAttributes(filename, attributes, context, Blacklist)
%typename is the type of name if it exists.  Empty string otherwise
%args is a containers.Map of all valid attributes
args = containers.Map;
type = struct('namespace', '', 'name', '', 'typename', '');
if isempty(attributes)
    return;
end
names = {attributes.Name};

typeDefMask = strcmp(names, 'neurodata_type');
hasTypeDef = any(typeDefMask);
if hasTypeDef
    typeDef = attributes(typeDefMask).Value;
    if iscellstr(typeDef)
        typeDef = typeDef{1};
    end
    type.name = typeDef;
end

namespaceMask = strcmp(names, 'namespace');
hasNamespace = any(namespaceMask);
if hasNamespace
    namespace = attributes(namespaceMask).Value;
    if iscellstr(namespace)
        namespace = namespace{1};
    end
    type.namespace = namespace;
end

if hasTypeDef && hasNamespace
    validNamespace = misc.str2validName(type.namespace);
    validName = misc.str2validName(type.name);
    type.typename = ['types.' validNamespace '.' validName];
end

blacklistMask = ismember(names, Blacklist.attributes);
deleteMask = typeDefMask | namespaceMask | blacklistMask;
attributes(deleteMask) = [];
for i=1:length(attributes)
    attr = attributes(i);
    fid = H5F.open(filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
    aid = H5A.open_by_name(fid, context, attr.Name);
    tid = H5A.get_type(aid);
    typename = io.getMatlabType(tid);
    
    if isscalar(attr.Value) && iscell(attr.Value)
        value = attr.Value{1};
    end
    
    if strcmp(typename, 'types.untyped.ObjectView')...
            || strcmp(typename, 'types.untyped.RegionView')
        args(attr.Name) = io.parseReference(aid, tid, value);
    elseif strcmp(typename, 'logical')
        args(attr.Name) = logical(H5T.get_member_value(tid, value));
    else
        args(attr.Name) = cast(attr.Value, typename);
    end
    H5T.close(tid);
    H5A.close(aid);
    H5F.close(fid);
end
end
