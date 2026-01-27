function checkDims(valueSize, validSizes, enforceScalarSize)
% CHECKDIMS - Validate a size value against a set of valid sizes
%
% types.util.CHECKDIMS(valsize, validSizes) given value size and a cell array 
% of valid sizes, validates that the value size matches at least one of them.
%
% types.util.CHECKDIMS(valsize, validSizes, enforceScalarSize) optionally
% enforces stricter validation for scalar/1D shapes. By default, MATLAB 
% vectors with shape [n,1] (column) or [1,n] (row) will pass validation 
% against a 1D size specification of [Inf], because vector data is typically 
% treated as 1D when written to file. However, in some cases (e.g., DataPipe 
% maxSize), the 2D shape [n,1] or [1,n] determines the actual shape in the 
% exported file. Set enforceScalarSize to true to reject 2D vector shapes 
% when a 1D shape like [Inf] is specified for validSize.
%
% Example:
%   % Without strict enforcement, [5,1] matches [Inf]:
%   types.util.checkDims([5,1], {Inf}, false);  % OK
%   
%   % With strict enforcement, [5,1] does NOT match [Inf]:
%   types.util.checkDims([5,1], {Inf}, true);   % Error
%   types.util.checkDims(5, {Inf}, true);       % OK

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
