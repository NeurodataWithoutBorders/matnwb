function val = correctType(val, type)
%CORRECTTYPE
%   Will error if type is simply incompatible
%   Will throw if casting is impossible

%check different types and correct

class_val = class(val); %store initial class

if any(strcmp(type, {'logical', 'bool'}))
    assert(islogical(val) || isnumeric(val),...
        'NWB:CorrectType:NonLogical',...
        'Value of type `%s` could not be coerced into a logical value.', class(val));
    val = logical(val);
    return;
end

assert(isnumeric(val), 'NWB:CorrectType:NonNumericType',...
    'Expected type to be numeric. Got `%s`', class(val));
if strcmp(type, 'numeric')
    return;
end

if any(strcmp(type, {'float', 'single', 'float32', 'double', 'float64'}))
    val = double(val);
    return;
end

assert(isempty(val) || isinteger(val) || all(0 == abs(val - fix(val))),...
    'NWB:CorrectType:FloatingPointTruncation',...
    'Converting to `%s` would have dropped floating point values.',...
    type);

maxVal = max(val, [], 'all');
minVal = min(val, [], 'all');

if ~isinteger(val)
    if startsWith(type, 'uint')
        assert(isempty(val) || (0 <= minVal && maxVal <= double(intmax('uint64'))),...
            'NWB:CorrectType:FloatingPointOutOfRange',...
            'Real value too large to fit into uint64');
        val = uint64(val);
    else
        assert(all(minVal >= double(intmin('int64')))...
            && all(maxVal <= double(intmax('int64'))),...
            'NWB:CorrectType:FloatingPointOutOfRange',...
            'Real value too large to fit into int64');
        val = int64(val);
    end
end

if strcmp(type, 'uint')
    type = 'uint8';
elseif strcmp(type, 'int')
    type = 'int8';
end

typeMatch = regexp(type, '(u?int)(\d+)', 'once', 'tokens');
prefix = typeMatch{1};
minSize = str2double(typeMatch{2});

assert(startsWith(class(val), prefix),...
    'NWB:CorrectType:IntegerSignage',...
    'Value must be of signage `%s`', prefix);

classMatch = regexp(class(val), 'u?int(\d+)', 'once', 'tokens');
classSize = str2double(classMatch{1});
if ~any(strcmpi(class_val, {'int8' 'int16' 'int32' 'int64'}))
    % correct type if integer byte size not specified
    intSizeScale = [8 16 32 64];
    for iSize = find(minSize == intSizeScale, 1):find(classSize == intSizeScale, 1)
        sizeType = sprintf('%s%d', prefix, intSizeScale(iSize));
        if all(minVal >= double(intmin(sizeType))) && all(maxVal <= double(intmax(sizeType)))
            val = cast(val, sizeType);
            break;
        end
    end
end
end