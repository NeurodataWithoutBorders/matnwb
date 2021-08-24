function val = correctType(val, type)
%CORRECTTYPE
%   Will error if type is simply incompatible
%   Will throw if casting is impossible

%check different types and correct

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

if any(strcmp(type, {'single', 'float32', 'double', 'float64'}))
    val = double(val);
    return;
end

assert(isempty(val) || isinteger(val) || all(0 == abs(val - fix(val))),...
    'NWB:CorrectType:FloatingPointTruncation',...
    'Converting to `%s` would have dropped floating point values.',...
    type);

if ~isinteger(val)
    if startsWith(type, 'uint')
        assert(all(val >= 0) && all(val <= double(intmax('uint64')), 'all'),...
            'NWB:CorrectType:FloatingPointOutOfRange',...
            'Real value too large to fit into uint64');
        val = uint64(val);
    else
        assert(all(val >= double(intmin('int64')))...
            && all(val <= double(intmax('int64'))),...
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

intSizeScale = [8 16 32 64];
for iSize = find(minSize == intSizeScale, 1):length(intSizeScale)
    sizeType = sprintf('%s%d', prefix, intSizeScale(iSize));
    if all(double(val) >= double(intmin(sizeType)), 'all')...
            && all(double(val) <= double(intmax(sizeType)), 'all')
        val = cast(val, sizeType);
        break;
    end
end
end