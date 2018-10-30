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
        'types.untyped.checkDtype: Compound Type must be a struct, table, or a containers.Map');
    if (isstruct(val) && isscalar(val)) || isa(val, 'containers.Map')
        %check for correct array shape
        sizes = zeros(length(names),1);
        for i=1:length(names)
            if isstruct(val)
                subv = val.(names{i});
            else
                subv = val(names{i});
            end
            assert(isvector(subv),...
                ['types.util.checkDtype: struct of arrays as a compound type ',...
                'cannot have multidimensional data in their fields.  Field data ',...
                'shape must be scalar or vector to be valid.']);
            sizes(i) = length(subv);
        end
        sizes = unique(sizes);
        assert(isscalar(sizes),...
            ['struct of arrays as a compound type ',...
            'contains mismatched number of elements with unique sizes: [%s].  ',...
            'Number of elements for each struct field must match to be valid.'], ...
            num2str(sizes));
    end
    for i=1:length(names)
        pnm = names{i};
        subnm = [name '.' pnm];
        typenm = type.(pnm);
        
        if (isstruct(val) && isscalar(val)) || istable(val)
            val.(pnm) = types.util.checkDtype(subnm,typenm,val.(pnm));
        elseif isstruct(val)
            for j=1:length(val)
                elem = val(j).(pnm);
                assert(~iscell(elem) && ...
                    (isempty(elem) || ...
                    (isscalar(elem) || (ischar(elem) && isvector(elem)))),...
                    ['Fields for an array of structs for '...
                'compound types should have non-cell scalar values or char arrays.']);
                val(j).(pnm) = types.util.checkDtype(subnm, typenm, elem);
            end
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
        dimsize = [1 ndims(val)];
        truval = val;
        if any(val.dims == 0)
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
        case {'double' 'int64' 'uint64' 'logical'}
            assert(isnumeric(val), errmsg);
            
            if strcmp(type, 'uint64') && any(reshape(val, [numel(val) 1]) < 0)
                warning('Property `%s` is a `uint64`.  Casted value will be zero.');
            end
            
            val = eval([type '(val)']);
        case 'isodatetime'
            assert(ischar(val) || iscellstr(val) || isa(val, 'datetime'), errmsg);
            if ischar(val) || iscellstr(val)
                val = datetime(val);
            end
        case 'char'
            assert(ischar(val) || iscellstr(val), errmsg);
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