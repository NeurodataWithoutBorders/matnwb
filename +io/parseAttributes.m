function [args, typename] = parseAttributes(filename, alist, context)
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
    elseif strcmp(attr.Datatype.Class, 'H5T_REFERENCE')
        fid = H5F.open(filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
        aid = H5A.open_by_name(fid, context, attr.Name);
        tid = H5A.get_type(aid);
        args(attr.Name) = io.parseReference(aid, tid, attr.Value);
        H5T.close(tid);
        H5A.close(aid);
        H5F.close(fid);
    elseif isscalar(attr.Value) && iscellstr(attr.Value)
        args(attr.Name) = attr.Value{1};
    else
        if iscellstr(attr.Value)
            attr.Value = strip(attr.Value);
        end
        args(attr.Name) = attr.Value;
    end
end
if ~isempty(type.namespace) && ~isempty(type.name)
    typename = ['types.' type.namespace '.' type.name];
end
end