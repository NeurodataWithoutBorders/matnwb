function val = checkDtype(name, type, val)
%ref
%any, double, int/uint, char
persistent WHITELIST;
if isempty(WHITELIST)
    WHITELIST = {...
        'types.untyped.ExternalLink'...
        'types.untyped.SoftLink'...
        };
end
if isstruct(type)
    names = fieldnames(type);
    assert(isstruct(val) || istable(val) || isa(val, 'containers.Map'), ...
        'When type is a struct, val should be a struct, table, or a containers.Map');
    for i=1:length(names)
        subnm = [name '.' names{i}];
        typenm = type.(names{i});
        if isstruct(val) || istable(val)
            val.(names{i}) = types.util.checkDtype(subnm,typenm,val.(names{i}));
        else
            val(names{i}) = types.util.checkDtype(subnm,typenm,val(names{i}));
        end
    end
else
    errmsg = ['Property `' name '` must be a ' type '.'];
    if isempty(val)
        return;
    end
    if isa(val, 'types.untyped.DataStub')
        %grab first element and check
        dimsize = [1 val.ndims()];
        truval = val;
        if any(val.dims() == 0)
            val = [];
        else
            val = val.load(ones(dimsize), ones(dimsize));
        end
    elseif isa(val, 'types.untyped.Anon')
        truval = val;
        val = val.value;
    else
        truval = [];
    end
    switch type
        case {'double' 'int64' 'uint64'}
            if ~isnumeric(val)
                error(errmsg);
            end
            
            if strcmp(type, 'uint64') && any(reshape(val, [numel(val) 1]) < 0)
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
    
    %reset to datastub/anon
    if ~isempty(truval)
        val = truval;
    end
end
end