function deserialized = deserialize_h5(serialized, matlabType)
%DESERIALIZE_H5 Deserialize h5 type to Matlab format
MSG_ID_CONTEXT = 'NWB:DeserializeH5:';

switch matlabType
    case 'types.untyped.ObjectView'
        deserialized = types.untyped.ObjectView.from_raw(obj, serialized);
    case 'types.untyped.RegionView'
        deserialized = types.untyhped.RegionView.from_raw(obj, serialized);
    case 'datetime'
        assert(iscellstr(serialized), [MSG_ID_CONTEXT 'InvalidType'],...
            'A serialized datetime value should be a string.');
        
        deserialized = datetime.empty(length(serialized), 0);
        for i = 1:length(serialized)
            deserialized(i) = parseIso8601(serialized{i});
        end
    case 'char'
        assert(iscellstr(serialized)...
            && isscalar(serialized),...
            [MSG_ID_CONTEXT 'MultiDimCharArray'],...
            'Multi-dimensional character arrays are not supported.');
        deserialized = serialized{1};
    otherwise
        deserialized = data;
end
end

function dt = parseIso8601(timestr)
iso8601_path = fullfile(...
    fileparts(which('NwbFile')),...
    'external_packages',...
    'datenum8601');
addpath(iso8601_path);

dnum = datenum8601(timestr);

% derive timezones as datetime doesn't do that by default
% one of:
% +-hh:mm
% +-hhmm
% +-hh
% Z
tzre_pattern = '(?:[+-]\d{2}(?::?\d{2})?|Z)$';
tzre_match = regexp(timestr, tzre_pattern, 'once');
if isempty(tzre_match)
    tz = 'local';
else
    tz = timestr(tzre_match:end);
    if strcmp(tz, 'Z')
        tz = 'UTC';
    end
end

dt = datetime(dnum(1), 'TimeZone', tz, 'ConvertFrom', 'datenum');
end
