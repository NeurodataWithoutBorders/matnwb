function value = checkDtype(name, typeDescriptor, value)
% checkDtype - Validates and corrects the data type of a given value
% 
% Syntax:
%   value = types.util.checkDtype(name, typeDescriptor, value) validates the
%   data type of the input value based on the provided type descriptor. If the 
%   value does not match the expected type, the function attempts to convert it 
%   to the correct type.
% 
% Input Arguments:
%   name - A string representing the name of the property being validated.
%   typeDescriptor - A structure describing the expected type of the value.
%   value - The value to be validated and potentially converted.
% 
% Output Arguments:
%   value - The validated or corrected value, which may have been converted 
%   to match the expected type.

    arguments
        name {mustBeTextScalar}
        typeDescriptor {mustBeValidTypeDescriptor}
        value
    end

    if canBeAnyType(typeDescriptor)
        value = validateAnyType(value);

    elseif isstruct(typeDescriptor) % Compound type processing
        value = checkDtypeForCompoundDataset(name, typeDescriptor, value);
    
    elseif isa(value, 'types.untyped.SoftLink')
        if ~isempty(value.target)
            value = types.util.validateSoftLink(name, value, typeDescriptor);
        else
            % Softlinks cannot be validated at this level.
        end
    
    elseif isempty(value) % Handle empty values
        % For certain types (numeric, logical, char), we replace [] with a typed 
        % empty value.
        if canWeCast(typeDescriptor)
            if isNumericType(typeDescriptor)
                value = types.util.correctType(value, typeDescriptor);
            else
                value = cast(value, typeDescriptor);
            end
        end
    else
        % Retrieve wrapped value for comparison with type descriptor (if wrapped)
        valueWrapper = [];
        if isWrapped(value, typeDescriptor)
            valueWrapper = value;
            value = unwrapValue(value);
        end
        
        if matnwb.utility.isNeurodataType(typeDescriptor)
            validateNeurodataType(name, value, typeDescriptor)
            correctedValue = value;
        else
            try
                correctedValue = types.util.correctType(value, typeDescriptor);
            catch MECause
                ME = MException('NWB:CheckDataType:InvalidConversion', ...
                    ['Error setting property ''%s'' because value cannot be ', ...
                    'converted to ''%s''.'], name, typeDescriptor);
                ME = ME.addCause(MECause);
                throw(ME);
            end
        end

        wasTypeCorrected = ~strcmp(class(correctedValue), class(value));
        if ~isempty(valueWrapper)
            if wasTypeCorrected
       
                % Special case: converting text (char/string) into MATLAB datetime.
                % HDF5 does not provide a native datetime type, so NWB stores times as
                % strings or numbers. Converting these values into datetime is expected
                % behavior and not an error. We therefore skip issuing a warning for this
                % conversion, even though the MATLAB class changes.
                skipWarning = isDatetimeConversion(correctedValue, value);
                
                if ~skipWarning
                    warning('NWB:CheckDataType:NeedsManualConversion',...
                        ['The value for property `%s` should be of type `%s`, ', ...
                        'but was `%s`. Please provide the correct type.'], ...
                        name, class(correctedValue), class(value));
                end
            end
            % Return the original data type. The wrapped value might just
            % be a sample and not the entire data set (i.e for DataStubs or
            % Datapipes)
            value = valueWrapper; % re-wrap value
        else
            value = correctedValue;
        end
    end
end

%% Local functions

function mustBeValidTypeDescriptor(typeDescriptor)
    isValid = isstruct(typeDescriptor) || ischar(typeDescriptor) || isstring(typeDescriptor);
    assert( isValid, ...
        'NWB:CheckDataType:InvalidTypeDescriptor', ...
        'Type descriptor must be a struct, character vector or a string.');
end

function value = checkDtypeForCompoundDataset(name, typeDescriptor, value)
    
    valueWrapper = [];
    if isWrapped(value, typeDescriptor)
        valueWrapper = value;
        
        if isa(value, 'types.untyped.DataStub') && value.isCompoundType()
            validateCompoundTypeDescriptor(name, typeDescriptor, value.dataType);
            % Return the stub - no need to unwrap and load data
            return;
        end
        
        value = unwrapValue(value);
    end

    validateCompoundValue(value)

    expectedFields = fieldnames(typeDescriptor);
    validateCompoundFields(expectedFields, value)

    if isScalarCompoundValue(value)
        assertFieldDataSameLength(expectedFields, value)
    end
        
    % Validate subfield types.
    parentName = name;
    for iField = 1:length(expectedFields)
        name = expectedFields{iField};
        subName = [parentName '.' name];
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

    if ~isempty(valueWrapper)
        value = valueWrapper; % re-wrap value
    end

    function validateCompoundFields(expectedFields, value)
        % Assert field names and order of fields are correct.
        if isstruct(value)
            valueFields = fieldnames(value);
        elseif isa(value, 'table') % table
            valueFields = value.Properties.VariableNames;
        else % Containers.Map
            valueFields = value.keys();
        end

        % Ensure the same fields are given as are defined in the
        % typedescriptor
        isValid = isempty(setdiff(expectedFields, valueFields)) ...
            && isempty(setdiff(valueFields, expectedFields)); 

        assert(isValid, ...
            'NWB:CheckDType:InvalidValue', ...
            'Compound type must only contain fields (%s)', strjoin(expectedFields, ', ') ...
            );
        
        if ~isa(value, 'containers.Map') % Map keys are unordered.
            for i = 1:length(expectedFields)
                assert(strcmp(expectedFields{i}, valueFields{i}), ...
                    'NWB:CheckDType:InvalidValue', ...
                    'Compound fields are out of order.\nExpected (%s) Got (%s)', ...
                    strjoin(expectedFields, ', '), strjoin(valueFields, ', '));
            end
        end
    end

    function tf = isScalarCompoundValue(value)
        tf = (isstruct(value) && isscalar(value)) || ...
            isa(value, 'containers.Map');
    end

    function assertFieldDataSameLength(expectedFields, value)
        % check for correct array shape
        fieldLengths = zeros(length(expectedFields), 1);
        for i = 1:length(expectedFields)
            if isstruct(value)
                subValue = value.(expectedFields{i});
            else
                subValue = value(expectedFields{i});
            end
            assert(isvector(subValue),...
                'NWB:CheckDType:InvalidShape',...
                ['struct of arrays as a compound type ',...
                'cannot have multidimensional data in their fields. ',...
                'Field data shape must be scalar or vector to be valid.']);
            if ischar(subValue)
                % Use size(subValue, 1) for character arrays to count rows 
                % (strings) correctly, since length() would return the total 
                % number of characters rather than the number of rows.
                fieldLengths(i) = size(subValue, 1);
            else
                fieldLengths(i) = length(subValue);
            end
        end
        uniqueFieldLengths = unique(fieldLengths);
        assert(isscalar(uniqueFieldLengths),...
            'NWB:CheckDType:InvalidShape',...
            ['struct of arrays as a compound type ',...
            'contains mismatched number of elements with unique sizes: [%s].  ',...
            'Number of elements for each struct field must match to be valid.'], ...
            num2str(uniqueFieldLengths));
    end
end

function validateCompoundValue(value)
    assert(isstruct(value) || istable(value) || isa(value, 'containers.Map'), ...
        'NWB:CheckDType:InvalidValue', ...
        ['Value of compound type must be a struct, table, or a ', ...
        'containers.Map but was a "%s"'], class(value) )
end

function tf = isCompoundValue(value)
    tf = isstruct(value) || istable(value) || isa(value, 'containers.Map');
end

function validateAnyCompoundValue(value)
    validateCompoundValue(value)

    if isstruct(value)
        fieldNames = fieldnames(value);

        if isscalar(value)
            assertFieldDataSameLengthForAnyCompound(fieldNames, value)
            for iField = 1:length(fieldNames)
                fieldValue = value.(fieldNames{iField});
                assert(~isCompoundValue(fieldValue), ...
                    'NWB:CheckDType:NestedCompoundNotSupported', ...
                    'Nested compound values are not supported')
                validateAnyType(fieldValue);
            end
        else
            for iField = 1:length(fieldNames)
                fieldName = fieldNames{iField};
                for iElem = 1:numel(value)
                    elem = value(iElem).(fieldName);
                    assert(~iscell(elem) && ...
                        (isempty(elem) || ...
                        (isscalar(elem) || (ischar(elem) && isvector(elem)))), ...
                        'NWB:CheckDType:InvalidType', ...
                        ['Fields for an array of structs for ' ...
                        'compound types should have non-cell scalar values or char arrays.']);
                    assert(~isCompoundValue(elem), ...
                        'NWB:CheckDType:NestedCompoundNotSupported', ...
                        'Nested compound values are not supported')
                    validateAnyType(elem);
                end
            end
        end
    elseif istable(value)
        fieldNames = value.Properties.VariableNames;
        for iField = 1:length(fieldNames)
            fieldValue = value.(fieldNames{iField});
            assert(~isCompoundValue(fieldValue), ...
                'NWB:CheckDType:NestedCompoundNotSupported', ...
                'Nested compound values are not supported')
            validateAnyType(fieldValue);
        end
    else % containers.Map
        fieldNames = value.keys();
        assertFieldDataSameLengthForAnyCompound(fieldNames, value)
        for iField = 1:length(fieldNames)
            fieldValue = value(fieldNames{iField});
            assert(~isCompoundValue(fieldValue), ...
                'NWB:CheckDType:NestedCompoundNotSupported', ...
                'Nested compound values are not supported')
            validateAnyType(fieldValue);
        end
    end
end

function assertFieldDataSameLengthForAnyCompound(fieldNames, value)
    fieldLengths = zeros(length(fieldNames), 1);

    for iField = 1:length(fieldNames)
        if isstruct(value)
            fieldValue = value.(fieldNames{iField});
        else
            fieldValue = value(fieldNames{iField});
        end

        assert(isvector(fieldValue), ...
            'NWB:CheckDType:InvalidShape', ...
            ['struct of arrays as a compound type ' ...
            'cannot have multidimensional data in their fields. ' ...
            'Field data shape must be scalar or vector to be valid.']);

        if ischar(fieldValue)
            fieldLengths(iField) = size(fieldValue, 1);
        else
            fieldLengths(iField) = length(fieldValue);
        end
    end

    uniqueFieldLengths = unique(fieldLengths);
    assert(isscalar(uniqueFieldLengths), ...
        'NWB:CheckDType:InvalidShape', ...
        ['struct of arrays as a compound type ' ...
        'contains mismatched number of elements with unique sizes: [%s].  ' ...
        'Number of elements for each struct field must match to be valid.'], ...
        num2str(uniqueFieldLengths));
end

function tf = canWeCast(typeDescriptor)
    replaceableNullTypes = getReplaceableNullTypes();
    tf = ischar(typeDescriptor) && ...
        any(strcmp(typeDescriptor, replaceableNullTypes));
end

function tf = isNumericType(typeDescriptor)
    tf = any(strcmp(typeDescriptor, getNumericTypes()));
end

function replaceableNullTypes = getReplaceableNullTypes()
    replaceableNullTypes = [{'char', 'logical'}, getNumericTypes()];
end

function numericTypes = getNumericTypes()
    numericTypes = { ...
        'single', 'double', ...
        'int8', 'uint8', ...
        'int16', 'uint16', ...
        'int32', 'uint32', ...
        'int64', 'uint64'};
end

function validateNeurodataType(name, value, typeDescriptor)
    isValid = isa(value, typeDescriptor);

    assert( isValid, ...
        'NWB:CheckDType:InvalidNeurodataType', ...
        ['Expected value for `%s` to be of type `%s`. ', ...
         'Instead it was `%s`'], name, typeDescriptor, class(value))
end

function tf = isDatetimeConversion(correctedValue, value)
    tf = isa(correctedValue, 'datetime') ...
        && (ischar(value) || isstring(value) || iscellstr(value));
end

function validateCompoundTypeDescriptor(name, expectedTypeDesc, actualTypeDesc)
%validateCompoundTypeDescriptor - Validate compound type descriptor
%   Validates that the compound type descriptor (of a DataStub) matches
%   the expected type descriptor without loading data from disk.
        
    % Get field names from both type descriptors
    expectedFields = fieldnames(expectedTypeDesc);
    actualFields = fieldnames(actualTypeDesc);
    
    % Check field count
    assert( length(expectedFields) == length(actualFields), ...
        'NWB:CheckDType:FieldCountMismatch', ...
        'Expected %d fields but DataStub has %d fields for ''%s''', ...
        length(expectedFields), length(actualFields), name);
    
    % Validate each field name, order, and type
    for i = 1:length(expectedFields)
        expectedName = expectedFields{i};
        actualName = actualFields{i};
        
        % Check field order (important for compound types)
        assert( strcmp(expectedName, actualName), ...
            'NWB:CheckDType:FieldOrderMismatch', ...
            ['Field order mismatch in ''%s'': expected ''%s'' at position ', ...
            '%d but got ''%s'''], ...
            name, expectedName, i, actualName);
        
        expectedType = expectedTypeDesc.(expectedName);
        actualType = actualTypeDesc.(expectedName);
        
        if isstruct(expectedType) && isstruct(actualType)
            error('NWB:CheckDType:NestedCompoundNotSupported', ...
                'Nested compound values are not supported')
        elseif isNumericType(expectedType)
            dummyValue = cast(0, actualType);
            % If this does not error, the numeric is valid:
            types.util.correctType(dummyValue, expectedType);

        else
            assert(strcmp(expectedType, actualType), ...
                'NWB:CheckDType:TypeMismatch', ...
                'Field ''%s.%s'' has type mismatch: expected ''%s'' but DataStub has ''%s''', ...
                name, expectedName, expectedType, actualType);
        end
    end
end

function tf = canBeAnyType(typeDescriptor)
    tf = (ischar(typeDescriptor) || isstring(typeDescriptor)) ...
        && strcmp(typeDescriptor, 'any');
end

function value = validateAnyType(value)
% validateAnyType - Validate values where any dtype is allowed

    persistent validBasicTypes
    if isempty(validBasicTypes)
        typeMap = spec.getBasicDTypeMap;
        validBasicTypes = string( unique(typeMap.values) );
    end
    
    valueType = class(value);

    if any(strcmp(valueType, validBasicTypes))
        return
    end

    % Special case: char equivalents that are also valid
    if isstring(value) || iscellstr(value)
        return
    end

    % Accept reference types
    if isa(value, 'types.untyped.ObjectView') || isa(value, 'types.untyped.RegionView')
        return
    end
    
    % Accept soft links and external links
    if isa(value, 'types.untyped.SoftLink') || isa(value, 'types.untyped.ExternalLink')
        return
    end

    % Accept compound values after validating their field contents
    if isCompoundValue(value)
        validateAnyCompoundValue(value)
        return
    end

    if isWrapped(value, 'any')
        unWrappedValue = unwrapValue(value);
        try
            validateAnyType(unWrappedValue);
            return
        catch exception
            throw(exception)
        end
    end

    % If we got here, the value is not a valid type for hdmf/nwb
    allowedTypes = [validBasicTypes; ...
        "types.untyped.ObjectView"; ...
        "types.untyped.RegionView"; ...
        "types.untyped.SoftLink"; ...
        "struct"; "table"; "containers.Map"];

    error('NWB:CheckDType:InvalidType', ...
        'Value was of type "%s" but must be one of the following types:\n%s', ...
        valueType, strjoin("  " + allowedTypes, newline))
end
