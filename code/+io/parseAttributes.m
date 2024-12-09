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
    switch attr.Datatype.Class
        case 'H5T_REFERENCE'
            fid = H5F.open(filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
            aid = H5A.open_by_name(fid, context, attr.Name);
            tid = H5A.get_type(aid);
            attributeValue = io.parseReference(aid, tid, attr.Value);
            H5T.close(tid);
            H5A.close(aid);
            H5F.close(fid);
        case 'H5T_ENUM'
            if io.isBool(attr.Datatype.Type)
                % attr.Value should be cell array of strings here since
                % MATLAB can't have arbitrary enum values.
                attributeValue = strcmp('TRUE', attr.Value);
            else
                warning('NWB:Attribute:UnknownEnum', ...
                    ['Encountered unknown enum under field `%s` with %d members. ' ...
                    'Will be saved as cell array of characters.'], ...
                    attr.Name, length(attr.Datatype.Type.Member));
            end
        otherwise
            attributeValue = attr.Value;
    end
    args(attr.Name) = attributeValue;
end
end
