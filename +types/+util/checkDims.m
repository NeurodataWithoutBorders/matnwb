function checkDims(valueSize, validSizes)
%% CHECKDIMS
% CHECKDIMS(valsize, validSizes) given value size and a cell array of valid
% sizes, validates that the value size matches at least one of them.

if any(valueSize == 0)
    return; %ignore empty arrays
end

for iValidSize = 1:length(validSizes)
    expectedSize = validSizes{iValidSize};
    expectedRank = length(expectedSize);

    if 1 == expectedRank
        % since MATLAB doesn't actually support single ranks,
        % we must check the ambiguous case where the vector might be
        % vertical or horizontal.
        isSizeMatch = getIsSizeMatch([expectedSize 1], valueSize) ...
            || getIsSizeMatch([1 expectedSize], valueSize);
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
tf = length(expectedSize) == length(actualSize) && all(openSizeMask | expectedSize == actualSize);
end

function s = printFormattedSize(sz)
s = strjoin(repmat({'%d'}, size(sz)), ' ');
end