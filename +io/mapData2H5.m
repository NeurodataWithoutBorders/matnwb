function [tid, sid, data] = mapData2H5(fid, type, data, forceArray)
%MAPDATA2H5 Convert MATLAB type specifier and data to HDF5 compatible data
%   Given base file_id, type string and data value, returns HDF5 type id, space id,
%   and properly converted data

if nargin < 4
    forceArray = false;
end

tid = io.getBaseType(type);

%determine space size
if ischar(data)
    if ~forceArray && size(data,1) == 1
        sid = H5S.create('H5S_SCALAR');
    else
        sid = H5S.create_simple(1, size(data,1), []);
    end
elseif ~forceArray && isscalar(data)
    sid = H5S.create('H5S_SCALAR');
else
    if isvector(data)
        nd = 1;
        dims = length(data);
    else
        nd = ndims(data);
        dims = size(data);
    end
    
    sid = H5S.create_simple(nd, fliplr(dims), []);
end

%% Do Data Conversions
switch type
    case {'types.untyped.RegionView' 'types.untyped.ObjectView'}
        %will throw errors if refdata DNE.  Caught at NWBData level.
        data = io.getRefData(fid, data);
    case 'logical'
        %In HDF5, HBOOL is mapped to INT32LE
        data = int32(data);
    case {'char' 'datetime' 'cell'}
        % yes, datetime can come from cell arrays as well.
        % note, cell strings fall through
        if (iscell(data) && all(cellfun('isclass', data, 'datetime'))) ||...
                isdatetime(data)
            if ~iscell(data)
                data = {data};
            end
            for i=1:length(data)
                if isempty(data{i}.TimeZone)
                    data{i}.TimeZone = 'local';
                end
                data{i}.Format = 'yyyy-MM-dd''T''HH:mm:ss.SSSSSSZZZZZ'; % ISO8601
                data{i} = char(data{i});
            end
        elseif ~iscell(data)
            data = mat2cell(data, ones(size(data,1),1), size(data,2));
        end
end

%% sanitize strings and cell strings
if iscellstr(data)
    for i=1:length(data)
        data{i} = char(unicode2native(data{i}));
    end
end