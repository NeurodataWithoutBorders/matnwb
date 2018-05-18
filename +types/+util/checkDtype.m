function val = checkDtype(name, type, val)
%ref
%any, double, int/uint, char
errmsg = ['Property `' name '` must be a ' type '.'];
persistent WHITELIST;
if isempty(WHITELIST)
    WHITELIST = {...
        'types.untyped.DataStub'...
        'types.untyped.ExternalLink'...
        'types.untyped.SoftLink'...
        'types.untyped.ObjectView'...
        'types.untyped.RegionView'...
        };
end
if isempty(val) || any(strcmp(class(val), WHITELIST))
    return;
end
switch type
    case {'double' 'int64' 'uint64'}
        if ~isnumeric(val)
            error(errmsg);
        end
        
        if strcmp(type, 'uint64') && val < 0
            warning('Property `%s` is a `uint64`.  Casted value will be zero.');
        end
        
        val = eval([type '(val)']);
    case 'char'
        if ~ischar(val) && ~iscellstr(val)
            error(errmsg);
        end
    otherwise %class, ref, or link
        noncell = false;
        if ~iscell(val)
            val = {val};
            noncell = true;
        end
        for i=1:length(val)
            subval = val{i};
            if isempty(subval)
                continue;
            end
            if ~isa(subval, type) && ~any(strcmp(class(subval), WHITELIST))
                error(errmsg);
            end
        end
        if noncell
            val = val{1};
        end
end

end