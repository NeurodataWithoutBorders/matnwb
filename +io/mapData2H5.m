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
    case {'char' 'datetime'}
        if isa(data, 'datetime')
            if isempty(data.TimeZone)
                data.TimeZone = 'local';
            end
            data.Format = 'yyyyMMdd''T''HHmmssZ'; % ISO8601
            data = char(data);
        end
        data = mat2cell(data, ones(size(data,1),1), size(data,2));
end

%% sanitize strings and cell strings
if iscellstr(data)
    for i=1:length(data)
        data{i} = native2unicode(unicode2native(data{i}), 'UTF-8');
    end
end