function val = correctType(val, type)
%CORRECTTYPE
%   Will error if type is simply incompatible
%   Will throw if casting to primitive type "type" is impossible

invalidConversionErrorId = 'MatNWB:TypeCorrection:InvalidConversion';
invalidConversionErrorMessage = sprintf( ...
    'Value of type `%s` cannot be converted to type `%s`.', class(val), type);

switch type
    case 'char'
        assert(isstring(val) || ischar(val) || iscellstr(val), ...
            invalidConversionErrorId, ...
            invalidConversionErrorMessage);
    case 'datetime'
        isHeterogeneousCell = iscell(val) ...
            && all(...
            cellfun('isclass', val, 'char') ...
            | cellfun('isclass', val, 'string')...
            | cellfun('isclass', val, 'datetime'));
        assert(ischar(val)...
            || isdatetime(val) ...
            || isstring(val) ...
            || isHeterogeneousCell, ...
            invalidConversionErrorId, invalidConversionErrorMessage);

        % convert strings to datetimes
        if ischar(val) || isstring(val) || iscell(val)
            val = str2dates(val);
        end

        % coerce time zone and specific output format.
        val.TimeZone = 'local';
        val.Format = 'yyyy-MM-dd''T''HH:mm:ss.SSSSSSZZZZZ';
    case {'single', 'double', 'int64', 'int32', 'int16', 'int8', 'uint64', ...
            'uint32', 'uint16', 'uint8'}
        assert(ischar(val) ...
            || iscellstr(val) ...
            || isstring(val) ...
            || isnumeric(val));

        dataLossWarnId = 'MatNWB:TypeCorrection:DataLoss';
        dataLossWarnMessageFormat = ['Converting value of type `%s` to type ' ...
            '`%s` will require dropping data.'];
        
        if ischar(val) || iscellstr(val) || isstring(val)
            val = str2double(val);
        end
        if ~isreal(val)
            warning(dataLossWarnId, dataLossWarnMessageFormat, ...
                class(val), type);
            val = real(val);
        end
        if strcmp(type, 'numeric')
            return;
        end

        isTypeFloat = any(strcmp(type, {'single', 'double'}));
        if isfloat(val) && ~isTypeFloat && any(round(val(:)) ~= val(:))
            % check if dropping the float drops data.
            warning(dataLossWarnId, dataLossWarnMessageFormat, ...
                class(val), type);
        end

        if isTypeFloat
            flatVal = val(:);
            isOutOfBounds = any(flatVal > realmax(type))...
                || any(flatVal < -realmax(type))...
                || any(flatVal(flatVal < 0) > -realmin(type))...
                || any(flatVal(flatVal > 0) < realmin(type));
        else
            isOutOfBounds = any(val(:) > intmax(type))...
                || any(val(:) < intmin(type));
        end

        if ~isOutOfBounds
            val = cast(val, type);
        elseif xor(isfloat(val), isTypeFloat)
            if isTypeFloat
                val = double(val);
            else
                val = cast(val, getNearestIntegralType(val, type));
            end
        end
    case 'logical'
        val = logical(val);
    otherwise % type may refer to an object or even a link
        assert(isa(val, type), ...
            invalidConversionErrorId, ...
            invalidConversionErrorMessage);
end
end

function integralType = getNearestIntegralType(val, type)
assert(startsWith(type, 'uint') || startsWith(type, 'int'), ...
    'type should be an integral type here (uintx, intx, etc.).');
assert(all(val(:) >= 0) || ~startsWith(type, 'u'), ...
    'MatNWB:TypeCorrection:CannotConvertSignage', ...
    ['Provided value contains negative values and would be ' ...
    'lost on conversion to type `%s`'], type);
typeMatches = regexp(type, 'u?int(?<typeBitSize>\d+)', 'names', 'once');
typeBitSize = str2double(typeMatches.typeBitSize);
bitSizes = [8, 16, 32, 64];
bitSizeStart = find(bitSizes == typeBitSize, 1);
if startsWith(type, 'u')
    matchTypePrefix = 'uint';
else
    matchTypePrefix = 'int';
end
for iBitSize=bitSizeStart:length(bitSizes)
    bitSize = bitSizes(iBitSize);
    matchType = sprintf('%s%d', matchTypePrefix, bitSize);
    if all(val(:) <= intmax(matchType)) && all(val(:) >= intmin(matchType))
        integralType = matchType;
        return;
    end
end
error('MatNWB:TypeCorrection:CannotConvertType', ...
    'Failed to find nearest integer type to satisfy value of type `%s`.', class(val));
end

function dt = str2dates(strings)
%STR2DATES converts a string array, character matrix, or cell array of 
% convertible types to a formatted date vector. Assumes type is one of the 
% above.

if ischar(strings)
    % split character matrix by row.
    strings = mat2cell(strings, ones(1, size(strings,1)));
elseif isstring(strings)
    strings = num2cell(strings);
end

datevals = cell(size(strings));
for i = 1:length(strings)
    if isdatetime(strings{i})
        datevals{i} = strings{i};
    else
        datevals{i} = datetime8601(strtrim(strings{i}));
    end
end
dt = [datevals{:}];
end

function dt = datetime8601(datestr)
addpath(fullfile(fileparts(which('NwbFile')), 'external_packages', 'datenum8601'));
[~, ~, format] = datenum8601(datestr);
format = format{1};
has_delimiters = format(1) == '*';
if has_delimiters
    format = format(2:end);
end

assert(strncmp(format, 'ymd', 3),...
    'NWB:CheckDType:DateTime:Unsupported8601',...
    'non-ymd formats not supported.');
separator = format(4);
if separator ~= ' '
    % non-space digits will error when specifying import format
    separator = ['''' separator ''''];
end

has_fractional_sec = isstrprop(format(8:end), 'digit');
if has_fractional_sec
    seconds_precision = str2double(format(8:end));
    if seconds_precision > 9
        warning('MatNWB:CheckDType:DateTime:LossySeconds',...
            ['Potential loss of time data detected.  MATLAB fractional seconds '...
            'precision is limited to 1 ns.  Extra precision will be truncated.']);
    end
end
day_segments = {'yyyy', 'MM', 'dd'};
time_segments = {'HH', 'mm', 'ss'};

if has_delimiters
    day_delimiter = '-';
    time_delimiter = ':';
else
    day_delimiter = '';
    time_delimiter = '';
end

day_format = strjoin(day_segments, day_delimiter);
time_format = strjoin(time_segments, time_delimiter);
format = [day_format separator time_format];
if has_fractional_sec
    format = sprintf('%s.%s', format, repmat('S', 1, seconds_precision));
end

[datestr, timezone] = derive_timezone(datestr);
dt = datetime(datestr,...
    'InputFormat', format,...
    'TimeZone', timezone);
end

function [datestr, timezone] = derive_timezone(datestr)
% one of:
% +-hh:mm
% +-hhmm
% +-hh
% Z

tzre_pattern = '(?:[+-]\d{2}(?::?\d{2})?|Z)$';
tzre_match = regexp(datestr, tzre_pattern, 'once');

if isempty(tzre_match)
    timezone = 'local';
else
    timezone = datestr(tzre_match:end);
    if strcmp(timezone, 'Z')
        timezone = 'UTC';
    end
    datestr = datestr(1:(tzre_match - 1));
end
end
