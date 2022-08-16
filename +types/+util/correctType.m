function val = correctType(val, type)
%CORRECTTYPE
%   Will error if type is simply incompatible
%   Will throw if casting to primitive type "type" is impossible

invalidConversionErrorId = 'MatNWB:TypeCorrection:InvalidConversion';
invalidConversionErrorMessage = sprintf( ...
    'Value of type `%s` cannot be converted to type `%s`.', class(val), type);

unicodeTypes = {'text', 'utf', 'utf8', 'utf-8'};
asciiTypes = {'ascii', 'bytes'};
dateTypes = {'isodatetime', 'datetime'};
floatingPointTypes = {'float', 'float32', 'double', 'float64'};
integralTypes = {'long', 'int64', 'int', 'int32', 'short', 'int16', 'int8', ...
    'uint64', 'uint32', 'uint16', 'uint8', 'numeric'};
logicalTypes = 'bool';

switch type
    case [unicodeTypes asciiTypes]
        assert(isstring(val) || ischar(val) || iscellstr(val), ...
            invalidConversionErrorId, ...
            invalidConversionErrorMessage);
    case dateTypes
        assert(ischar(val)...
            || iscellstr(val)...
            || isdatetime(val) ...
            || isstring(val), ...
            invalidConversionErrorId, invalidConversionErrorMessage);

        % convert strings to datetimes
        if ischar(val) || iscellstr(val) || isstring(val)
            val = str2dates(val);
        end

        % coerce time zone and specific output format.
        val.TimeZone = 'local';
        val.Format = 'yyyy-MM-dd''T''HH:mm:ss.SSSSSSZZZZZ';
    case [floatingPointTypes integralTypes]
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
        if getIsNumericDowncastingNeeded(val, type)
            warning(dataLossWarnId, dataLossWarnMessageFormat, ...
                class(val), type);
        end
        val = cast(val, nwb2MatlabNumericType(type));
    case logicalTypes
        val = logical(val);
    otherwise % type may refer to an object or even a link
        assert(isa(val, type), ...
            invalidConversionErrorId, ...
            invalidConversionErrorMessage);
end
end

function tf = getIsNumericDowncastingNeeded(val, type)
validateattributes(val, {'numeric'}, {});
validateattributes(type, {'char'}, {'scalartext'});

type = nwb2MatlabNumericType(type);
isTypeFloat = any(strcmp(type, {'single', 'double'}));
typeSize = io.getMatTypesSize(nwb2matNumerictype(type));
valTypeSize = io.getMatTypeSize(class(val));

isTypeUnsigned = any(strcmp(type, ...
    {'uint8', 'uint16', 'uint32', 'uint64'}));

tf = (~isfloat(val) && isTypeFloat)...
    || (isTypeUnsigned && typeSize < valTypeSize)...
    || (~isTypeUnsigned && typeSize <= valTypeSize);
end

function matTypeStr = nwb2MatlabNumericType(type)
%nwb2MatNumericType given NWB spec language numeric type, converts to its
%equivalent in MATLAB format.
switch type
    case {'float', 'float32'}
        matTypeStr = 'single';
    case {'double', 'float64'}
        matTypeStr = 'double';
    case {'long', 'int64'}
        matTypeStr = 'int64';
    case {'int', 'int32'}
        matTypeStr = 'int32';
    case {'short', 'int16'}
        matTypeStr = 'int16';
    case {'int8'}
        matTypeStr = 'int8';
    case {'uint64'}
        matTypeStr = 'uint64';
    case {'uint32'}
        matTypeStr = 'uint32';
    case {'uint16'}
        matTypeStr = 'uint16';
    case {'uint8'}
        matTypeStr = 'uint8';
    otherwise
        error('MatNWB:NumericTypeMapping:InvalidMapping', ...
            'Encountered unknown nwb specification type `%s`.', type);
end
end

function dt = str2dates(strings)
%STR2DATES converts a string array, character matrix, or cell array of
%   character vectors to a formatted date vector. Assumes type is one of
%   the above.

if ischar(strings)
    % split character matrix by row.
    strings = mat2cell(strings, ones(1, size(strings,1)));
elseif isstring(strings)
    strings = num2cell(strings);
end

datevals = cell(size(strings));
for i = 1:length(strings)
    datevals{i} = datetime8601(strtrim(strings{i}));
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
