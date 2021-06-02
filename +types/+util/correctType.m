function val = correctType(val, type)
%CORRECTTYPE
%   Will error if type is simply incompatible
%   Will throw if casting is impossible

%check different types and correct

if startsWith(type, 'float')
% Compatibility with PyNWB
%     if strcmp(type, 'float32')
%         val = single(val);
%     else
        val = double(val);
%     end
elseif startsWith(type, 'int') || startsWith(type, 'uint')
    if strcmp(type, 'int')
        val = int64(val);
    elseif strcmp(type, 'uint')
        val = uint64(val);
    else
        val = feval(fitIntType(val, type), val);
    end
elseif strcmp(type, 'numeric') && ~isnumeric(val)
    val = double(val);
elseif strcmp(type, 'bool')
    val = logical(val);
end
end

function fittingIntType = fitIntType(val, minType)
intSizeScale = [8 16 32 64];
typeMatch = regexp(minType, '(u?int)(\d+)', 'once', 'tokens');
prefix = typeMatch{1};
minSize = str2double(typeMatch{2});

minVal = min(val(:));
maxVal = max(val(:));
minSizeMask = intSizeScale == minSize;
assert(any(minSizeMask), 'NWB:CorrectType:InvalidIntSize',...
    'Minimum integer size `%s` not supported.', minType);
for i = find(minSizeMask, 1):length(intSizeScale)
    fittingIntType = sprintf('%s%d', prefix, intSizeScale(i));
    if all(intmin(fittingIntType) <= minVal) && all(intmax(fittingIntType) >= maxVal)
        return;
    end
end

error('NWB:CorrectType:UnfittableInt', 'Could not fit integer into range %d-%d',...
    minVal, maxVal);
end