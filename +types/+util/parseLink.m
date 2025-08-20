function [result, ivarargin] = parseLink(obj, pname, type, varargin)
    assert(mod(length(varargin),2) == 0, 'Malformed varargin.  Should be even');
    
    result = [];

    ikeys = false(size(varargin));
    defprops = properties(obj);
    for i=1:2:length(varargin)
        if any(strcmp(varargin{i}, defprops))
            continue;
        end

        arg = varargin{i+1};
        if isa(arg, 'types.untyped.SoftLink')
            if ~isempty(arg.target)
                ikeys(i) = isa(arg.target, type);
            elseif ~isempty(arg.target_type)
                ikeys(i) = strcmp(arg.target_type, type);
            end
        else
            ikeys(i) = isa(arg, type);
        end
    end
    ivals = circshift(ikeys,1);

    ivarargin = ikeys | ivals;

    if ~any(ikeys)
        return;
    end

    if isa(obj.(pname), 'types.untyped.Set') % Todo: Will there be cases where links can have different target types?
        set = obj.(pname);
        validationFunction = @(nm, val)types.util.checkConstraint(pname, nm, struct(), {type}, val);
        if set.Count == 0
            % construct set from empty with generated map.
            set = types.untyped.Set(containers.Map(varargin(ikeys), varargin(ivals)), validationFunction);
        else
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
        result = set;
    else

        assert(isempty(obj.(pname)), ...
        'NWB:ParseLink:OperationNotSupported', ...
        ['Link parsing not supported for non-empty properties ("%s"). ', ...
        'Please report if you see this error'], pname)

        % Todo: If input is not a soft link, but the type itself, need
        % to use types.util.validateLink
        valIndices = find(ivals);
        result = cell(1, numel(valIndices));
        for i = 1:numel(valIndices)
            arg = varargin{valIndices(i)};
            if isa(arg, type)
                result{i} = types.util.validateSoftLink(pname, arg, type);
            else
                result{i} = arg;
            end
        end
        % Return as array of SoftLinks
        result = [result{:}];
    end
end

