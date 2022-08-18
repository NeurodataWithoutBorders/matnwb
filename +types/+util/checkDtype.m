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

%% compound type processing
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
                'NWB:CheckDType:InvalidShape',...
                ['struct of arrays as a compound type ',...
                'cannot have multidimensional data in their fields. ',...
                'Field data shape must be scalar or vector to be valid.']);
            sizes(i) = length(subv);
        end
        sizes = unique(sizes);
        assert(isscalar(sizes),...
            'NWB:CheckDType:InvalidShape',...
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
                    'NWB:CheckDType:InvalidType',...
                    ['Fields for an array of structs for '...
                    'compound types should have non-cell scalar values or char arrays.']);
                val(j).(pnm) = types.util.checkDtype(subnm, typenm, elem);
            end
        else
            val(names{i}) = types.util.checkDtype(subnm,typenm,val(names{i}));
        end
    end
    return;
end


%% primitives
if isempty(val) ... % MATLAB's "null" operator. Even if it's numeric, you can replace it with any class.
        || isa(val, 'types.untyped.SoftLink') % Softlinks cannot be validated at this level.
    return;
end

% retrieve sample of val
if isa(val, 'types.untyped.DataStub')
    %grab first element and check
    valueWrapper = val;
    if any(val.dims == 0)
        val = [];
    else
        val = val.load(1);
    end
elseif isa(val, 'types.untyped.Anon')
    valueWrapper = val;
    val = val.value;
elseif isa(val, 'types.untyped.ExternalLink') &&...
        ~strcmp(type, 'types.untyped.ExternalLink')
    valueWrapper = val;
    val = val.deref();
elseif isa(val, 'types.untyped.DataPipe')
    valueWrapper = val;
    val = cast([], val.dataType);
else
    valueWrapper = [];
end

correctedValue = types.util.correctType(val, type);
% this specific conversion is fine as HDF5 doesn't have a representative
% datetime type. Thus we suppress the warning for this case.
isDatetimeConversion = isa(correctedValue, 'datetime')...
    && (ischar(val) || isstring(val) || iscellstr(val));
if ~isempty(valueWrapper) ...
        && ~strcmp(class(correctedValue), class(val)) ...
        && ~isDatetimeConversion
    warning('MatNWB:CheckDataType:NeedsManualConversion',...
            'Property `%s` is not of type `%s` and should be corrected by the user.', ...
            name, class(correctedValue));
else
    val = correctedValue;
end

% re-wrap value
if ~isempty(valueWrapper)
    val = valueWrapper;
end
end
