function [tid, sid, data] = mapData2H5(fid, type, data)
%MAPDATA2H5 Convert MATLAB type specifier and data to HDF5 compatible data
%   Given base file_id, type string and data value, returns HDF5 type id, space id,
%   and properly converted data

tid = io.getBaseType(type, data);

if ischar(data)
    data = mat2cell(data, ones(size(data,1),1), size(data,2));
    for i=1:length(data)
        data{i} = char(unicode2native(data{i}));
    end
    if isscalar(data)
        sid = H5S.create('H5S_SCALAR');
    else
        sid = H5S.create_simple(1, size(data,1), []);
    end
elseif isscalar(data)
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
    case 'datetime'
        data = datestr(data, 30);
        data = mat2cell(data, ones(size(data,1),1), size(data,2));
        for i=1:length(data)
            data{i} = char(unicode2native(data{i}));
        end
end