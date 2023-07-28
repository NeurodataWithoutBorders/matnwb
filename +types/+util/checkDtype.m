function value = checkDtype(name, typeDescriptor, value)
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
if isstruct(typeDescriptor)
    expectedFields = fieldnames(typeDescriptor);
    assert(isstruct(value) || istable(value) || isa(value, 'containers.Map') ...
        , 'NWB:CheckDType:InvalidValue' ...
        , 'Compound Type must be a struct, table, or a containers.Map' ...
        );

    % assert field names and order of fields is correct.
    if isstruct(value)
        valueFields = fieldnames(value);
    else % table
        valueFields = value.Properties.VariableNames;
    end
    assert(isempty(setdiff(expectedFields, valueFields)) ...
        , 'NWB:CheckDType:InvalidValue' ...
        , 'Compound type must only contain fields (%s)', strjoin(expectedFields, ', ') ...
        );
    for iField = 1:length(expectedFields)
        assert(strcmp(expectedFields{iField}, valueFields{iField}) ...
            , 'NWB:CheckDType:InvalidValue' ...
            , 'Compound fields are out of order.\nExpected (%s) Got (%s)' ...
            , strjoin(expectedFields, ', '), strjoin(valueFields, ', '));
    end
    
    if (isstruct(value) && isscalar(value)) || isa(value, 'containers.Map')
        % check for correct array shape
        fieldSizes = zeros(length(expectedFields),1);
        for iField = 1:length(expectedFields)
            if isstruct(value)
                subValue = value.(expectedFields{iField});
            else
                subValue = value(expectedFields{iField});
            end
            assert(isvector(subValue),...
                'NWB:CheckDType:InvalidShape',...
                ['struct of arrays as a compound type ',...
                'cannot have multidimensional data in their fields. ',...
                'Field data shape must be scalar or vector to be valid.']);
            fieldSizes(iField) = length(subValue);
        end
        fieldSizes = unique(fieldSizes);
        assert(isscalar(fieldSizes),...
            'NWB:CheckDType:InvalidShape',...
            ['struct of arrays as a compound type ',...
            'contains mismatched number of elements with unique sizes: [%s].  ',...
            'Number of elements for each struct field must match to be valid.'], ...
            num2str(fieldSizes));
    end

    for iField = 1:length(expectedFields)
        % validate subfield types.
        name = expectedFields{iField};
        subName = [name '.' name];
        subType = typeDescriptor.(name);

        if (isstruct(value) && isscalar(value)) || istable(value)
            % scalar struct or table with columns.
            value.(name) = types.util.checkDtype(subName,subType,value.(name));
        elseif isstruct(value)
            % array of structs
            for j=1:length(value)
                elem = value(j).(name);
                assert(~iscell(elem) && ...
                    (isempty(elem) || ...
                    (isscalar(elem) || (ischar(elem) && isvector(elem)))),...
                    'NWB:CheckDType:InvalidType',...
                    ['Fields for an array of structs for '...
                    'compound types should have non-cell scalar values or char arrays.']);
                value(j).(name) = types.util.checkDtype(subName, subType, elem);
            end
        else
            value(expectedFields{iField}) = types.util.checkDtype( ...
                subName, subType, value(expectedFields{iField}));
        end
    end
    return;
end


%% primitives

if isa(value, 'types.untyped.SoftLink')
    % Softlinks cannot be validated at this level.
    return;
end

if isempty(value)
    % MATLAB's "null" operator. Even if it's numeric, you can replace it with any class.
    % we can replace empty values with their equivalents, however.
    replaceableNullTypes = {...
        'char' ...
        , 'logical' ...
        , 'single', 'double' ...
        , 'int8', 'uint8' ...
        , 'int16', 'uint16' ...
        , 'int32', 'uint32' ...
        , 'int64', 'uint64' ...
        };
    if ischar(typeDescriptor) && any(strcmp(typeDescriptor, replaceableNullTypes))
        value = cast(value, typeDescriptor);
    end
    return;
end

% retrieve sample of val
if isa(value, 'types.untyped.DataStub')
    %grab first element and check
    valueWrapper = value;
    if any(value.dims == 0)
        value = [];
    else
        value = value.load(1);
    end
elseif isa(value, 'types.untyped.Anon')
    valueWrapper = value;
    value = value.value;
elseif isa(value, 'types.untyped.ExternalLink') &&...
        ~strcmp(typeDescriptor, 'types.untyped.ExternalLink')
    valueWrapper = value;
    value = value.deref();
elseif isa(value, 'types.untyped.DataPipe')
    valueWrapper = value;
    value = cast([], value.dataType);
else
    valueWrapper = [];
end

correctedValue = types.util.correctType(value, typeDescriptor);
% this specific conversion is fine as HDF5 doesn't have a representative
% datetime type. Thus we suppress the warning for this case.
isDatetimeConversion = isa(correctedValue, 'datetime')...
    && (ischar(value) || isstring(value) || iscellstr(value));
if ~isempty(valueWrapper) ...
        && ~strcmp(class(correctedValue), class(value)) ...
        && ~isDatetimeConversion
    warning('NWB:CheckDataType:NeedsManualConversion',...
            'Property `%s` is not of type `%s` and should be corrected by the user.', ...
            name, class(correctedValue));
else
    value = correctedValue;
end

% re-wrap value
if ~isempty(valueWrapper)
    value = valueWrapper;
end
end
