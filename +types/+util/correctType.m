function val = correctType(val, type)
%CORRECTTYPE
%   Will error if type is simply incompatible
%   Will throw if casting to primitive type "type" is impossible

invalidConversionErrorId = 'NWB:TypeCorrection:InvalidConversion';
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
                class(val), type);
            val = castedValue;
        end
    case 'logical'
        val = logical(val);
    otherwise % type may refer to an object or even a link
        assert(isa(val, type), ...
            invalidConversionErrorId, ...
            invalidConversionErrorMessage);
end
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
        warning('NWB:CheckDType:DateTime:LossySeconds',...
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
