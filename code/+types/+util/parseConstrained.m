function [set, ivarargin] = parseConstrained(obj, pname, type, varargin)
    assert(mod(length(varargin),2) == 0, 'Malformed varargin.  Should be even');
    ikeys = false(size(varargin));
    defprops = properties(obj);
    for i=1:2:length(varargin)
        if any(strcmp(varargin{i}, defprops))
            continue;
        end

        arg = varargin{i+1};
        if isa(arg, 'types.untyped.ExternalLink')
            ikeys(i) = isa(arg.deref(), type);
            continue;
        end

        ikeys(i) = isa(arg, type) || isa(arg, 'types.untyped.SoftLink');
    end
    ivals = circshift(ikeys,1);

    ivarargin = ikeys | ivals;

    if isa(obj.(pname), 'types.untyped.Set')
        set = obj.(pname);
    else
        set = types.untyped.Set();
    end

    if ~any(ikeys)
        return;
    end

    validationFunction = @(nm, val)types.util.checkConstraint(pname, nm, struct(), {type}, val);

    if 0 == set.Count
        % construct set from empty with generated map.
        set = types.untyped.Set(containers.Map(varargin(ikeys), varargin(ivals)), validationFunction);
        return;
    end

    % append to currently existing set.
    set.setValidationFcn(validationFunction);

    keyIndices = find(ikeys);
    valIndices = find(ivals);
    if iscolumn(keyIndices) % for loops only work with row arrays.
        keyIndices = keyIndices .';
    end
    if iscolumn(valIndices)
        valIndices = valIndices .';
    end

    % create a for loop iteration where iKeyValue is a 2x1 index vector
    % representing each column of [keyIndices; valIndices]
    for iKeyValue = [keyIndices; valIndices]
        set.set(varargin{iKeyValue(1)}, varargin{iKeyValue(2)});
    end
end