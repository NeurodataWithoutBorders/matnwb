function checkDims(valueSize, validSizes, enforceScalarSize)
% CHECKDIMS - Validate a size value against a set of valid sizes
%
% types.util.CHECKDIMS(valsize, validSizes) given value size and a cell array 
% of valid sizes, validates that the value size matches at least one of them.
%
% types.util.CHECKDIMS(valsize, validSizes, enforceScalarSize) optionally
% enforces stricter validation for vectors. By default, MATLAB vectors 
% (column: [n,1], row: [1,n]) pass validation against a 1D size (Inf), 
% because vector data is typically treated as 1D when written to file. 
% However, DataPipe may write vector data as 2D. To prevent 2D sizes from 
% being accepted as 1D, use the enforceScalarSize flag.

if nargin < 3 % Set default value for enforceScalarSize if not provided
    enforceScalarSize = false;
end

if any(valueSize == 0)
    return; %ignore empty arrays
end

for iValidSize = 1:length(validSizes)
    expectedSize = validSizes{iValidSize};

    if isscalar(expectedSize)
        if enforceScalarSize
            isSizeMatch = isscalar(valueSize) && ...
                (isinf(expectedSize) || valueSize == expectedSize);
        else
            isSizeMatch = getIsSizeMatch([1 expectedSize], valueSize)...
                || getIsSizeMatch([expectedSize 1], valueSize);
        end
    else
        isSizeMatch = getIsSizeMatch(expectedSize, valueSize);
    end

    if isSizeMatch
        return;
    end
end

%% Validation Failed

valueSizeFormat = ['[' printFormattedSize(valueSize) ']'];

%format into cell array of strings of form `[Inf]` then join
validSizeFormattedList = cell(size(validSizes));
for iValidSize = 1:length(validSizes)
    validSize = validSizes{iValidSize};
    validSizeFormat = ['    - Rank %d with dimensions of size: [' printFormattedSize(validSize)  ']'];
    validSize = num2cell(validSize);
    validSizeFormattedList{iValidSize} = sprintf(validSizeFormat, length(validSize), validSize{:});
end

valueSize = num2cell(valueSize);
error('NWB:CheckDims:InvalidDimensions',...
    strrep(sprintf( ...
    ['Value of size ' valueSizeFormat ' is invalid.  Must be one of:\n%s'],...
    valueSize{:}, strjoin(validSizeFormattedList, newline)), 'Inf', 'Any'));
end

function tf = getIsSizeMatch(expectedSize, actualSize)
openSizeMask = isinf(expectedSize);
if length(actualSize) < length(expectedSize)
    % Pad actualSize with ones to match the length of expectedSize.
    % For example, [3,3] becomes [3,3,1] when compared with [inf,inf,inf].
    actualSize = [actualSize ones(1, length(expectedSize) - length(actualSize))];
end

if length(actualSize) > length(expectedSize)
    tf = false;
else
    tf = all(openSizeMask | expectedSize == actualSize);
end
end

function s = printFormattedSize(sz)
s = strjoin(repmat({'%d'}, size(sz)), ' ');
end
