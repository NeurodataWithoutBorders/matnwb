function [set, ivarargin] = parseConstrained(obj, pname, type, varargin)
    assert(mod(length(varargin),2) == 0, 'Malformed varargin.  Should be even');
    ikeys = false(size(varargin));
    defprops = properties(obj);

    isLink = false;

    % Detect and normalize link types.
    % If the typename is prefixed with 'Link:', mark it as a link
    % and strip the prefix so the typename is the name of a data type.
    if startsWith(type, 'Link:')
        isLink = true;
        type = extractAfter(type, 'Link:');
    end

    for i=1:2:length(varargin)
        if any(strcmp(varargin{i}, defprops)) && ~strcmp(varargin{i}, pname)
            continue;
        end

        arg = varargin{i+1};
        if isa(arg, 'types.untyped.ExternalLink')
            ikeys(i) = isa(arg.deref(), type);
            continue;
        elseif isa(arg, 'types.untyped.SoftLink')
            if ~isempty(arg.target)
                ikeys(i) = isa(arg.target, type);
            elseif ~isempty(arg.target_type)
                ikeys(i) = types.util.internal.isNameOfA(arg.target_type, type);
            end
        else
            ikeys(i) = isa(arg, type);
        end
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

    if isLink
        validationFunction = @(nm, val)types.util.validateSoftLink(pname, val, type);
    else
        validationFunction = @(nm, val)types.util.checkConstraint(pname, nm, struct(), {type}, val);
    end

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