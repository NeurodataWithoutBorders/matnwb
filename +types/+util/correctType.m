function val = correctType(val, type)
    %CORRECTTYPE
    %   Will error if type is simply incompatible
    %   Will throw if casting to primitive type "type" is impossible
    
    errorId = 'NWB:TypeCorrection:InvalidConversion';
    errorTemplate = sprintf( ...
        'Value of type `%s` cannot be converted to type `%s`:\n  %%s', class(val), type ...
    );
    
    switch type
        case 'char'
            errorMessage = sprintf(errorTemplate, ...
                sprintf('value was not a valid string type. got %s instead', class(val)) ...
            );
            assert(isstring(val) || ischar(val) || iscellstr(val), ...
                errorId, ...
                errorMessage ...
            );
        case 'datetime'
            isCellString = iscellstr(val) || (iscell(val) && all(cellfun('isclass', val, 'string')));
            isCellDatetime = iscell(val) && all(cellfun('isclass', val, 'datetime'));
            isHeterogeneousCell = isCellString || isCellDatetime;
            assert(ischar(val) || isdatetime(val) || isstring(val) || isHeterogeneousCell, ...
                errorId, sprintf(errorTemplate, 'value is not a timestamp or datetime object'));
            
            % convert strings to datetimes
            if ischar(val) || isstring(val) || isCellString
                val = formatDatetime(io.timestamp2datetime(val));
                return;
            end
            if isdatetime(val)
                val = num2cell(val);
            end
            
            % set format depending on default values.
            for iDatetime = 1:length(val)
                % note, must be a for loop since datetimes with/without timezones cannot be
                % concatenated.
                val{iDatetime} = formatDatetime(val{iDatetime});
            end
        case {'single', 'double', 'int64', 'int32', 'int16', 'int8', 'uint64', ...
                'uint32', 'uint16', 'uint8'}
            errorMessage = sprintf(errorTemplate ...
                , sprintf('type %s is not numeric or cannot be converted to a numeric value.', class(type)) ...
            );
            assert(ischar(val) || iscellstr(val) || isstring(val) || isnumeric(val) ...
                , errorId, errorMessage ...
            );
            
            if ischar(val) || iscellstr(val) || isstring(val)
                val = str2double(val);
            end
            
            % find nearest type and convert if necessary.
            nearestType = findNearestType(val, type);
            if ~strcmp(nearestType, class(val))
                castedValue = cast(val, nearestType);
                assert(isequal(castedValue, val), ...
                    'NWB:TypeCorrection:PrecisionLossDetected', ...
                    ['Could not convert data value of type `%s` to type `%s`. ' ...
                    'Precision loss detected.'], ...
                    class(val), type ...
                );
                val = castedValue;
            end
        case 'logical'
            val = logical(val);
        otherwise % type may refer to an object or even a link
            errorMessage = sprintf(errorTemplate ...
                , sprintf('value is not instance of type %s. Got type %s instead', type, class(val)));
            assert(isa(val, type), errorId, errorMessage);
    end
end

function Datetime = formatDatetime(Datetime)
    if all(cellfun('isempty', {Datetime.TimeZone}))
        formatString = 'yyyy-MM-dd''T''HH:mm:ss.SSSSSS';
    else
        formatString = 'yyyy-MM-dd''T''HH:mm:ss.SSSSSSZZZZZ';
    end
    [Datetime.Format] = formatString;
end

function nearestType = findNearestType(val, type)
    %FINDNEARESTTYPE given a value of some type. Find the nearest equivalent
    %type whose size matches that of the preferred type but can still hold the
    %stored value.
    
    dataLossWarnId = 'NWB:TypeCorrection:DataLoss';
    dataLossWarnMessageFormat = ['Converting value of type `%s` to type ' ...
        '`%s` may drop data precision.'];
    
    if ~isreal(val)
        warning(dataLossWarnId, dataLossWarnMessageFormat, ...
            class(val), type);
        val = real(val);
    end
    
    if strcmp(type, 'numeric') || strcmp(class(val), type)
        nearestType = class(val);
        return;
    end
    
    isTypeFloat = any(strcmp(type, {'single', 'double'}));
    isTypeUnsigned = ~isTypeFloat && startsWith(type, 'u');
    isValueTypeUnsigned = ~isfloat(val) && startsWith(class(val), 'u');
    
    valueTypeBitSize = 8 * io.getMatTypeSize(class(val));
    preferredTypeBitSize = 8 * io.getMatTypeSize(type);
    idealTypeBitSize = max(valueTypeBitSize, preferredTypeBitSize);
    
    % In certain classes of conversion, simply scaling upwards in size resolves
    % what would otherwise be an error in conversion. For instance: conversion
    % from an "int32" type should be stored in a "double" because a "single"
    % cannot contain all "int32" values (due to the mantissa). A similar case
    % exists when converting from unsigned types to signed types ("uint32" ->
    % "int32" should actually return "int64" as it ideal type).
    if valueTypeBitSize == idealTypeBitSize ...
            && ((isValueTypeUnsigned && ~isTypeUnsigned) ...
            || (~isfloat(val) && isTypeFloat))
        idealTypeBitSize = min(64, 2 * idealTypeBitSize);
    end
    
    if isTypeFloat
        if 64 == idealTypeBitSize
            nearestType = 'double';
        else
            nearestType = 'single';
        end
    else
        if isTypeUnsigned
            typePrefix = 'uint';
        else
            typePrefix = 'int';
        end
        nearestType = sprintf('%s%d', typePrefix, idealTypeBitSize);
    end
end
