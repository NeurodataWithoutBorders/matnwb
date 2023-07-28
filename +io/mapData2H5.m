function [tid, sid, data] = mapData2H5(fid, data, varargin)
%MAPDATA2H5 Convert MATLAB type specifier and data to HDF5 compatible data
%   Given base file_id, type string and data value, returns HDF5 type id, space id,
%   and properly converted data

forceArray = any(strcmp('forceArray', varargin));
forceChunked = any(strcmp('forceChunking', varargin));

if iscell(data)
    assert(...
        iscellstr(data) ...
        || all(cellfun('isclass', data, 'datetime')) ...
        || all(cellfun('isclass', data, 'string')) ...
        , 'NWB:MapData:NonCellStr', ['Cell arrays must be cell arrays of character vectors. ' ...
        'Cell arrays of other types are not supported.']);
end
tid = io.getBaseType(class(data));

% max size is always unlimited
unlimited_size = H5ML.get_constant_value('H5S_UNLIMITED');
%determine space size
if ischar(data)
    if ~forceArray && size(data,1) == 1
        sid = H5S.create('H5S_SCALAR');
    else
        dims = size(data, 1);
        if forceChunked
            max_dims = repmat(unlimited_size, size(dims));
        else
            max_dims = [];
        end
        sid = H5S.create_simple(1, size(data,1), max_dims);
    end
elseif ~forceArray && ~iscell(data) && isscalar(data)
    sid = H5S.create('H5S_SCALAR');
elseif ~forceChunked && isempty(data)
    sid = H5S.create_simple(1, 0, 0);
else
    if isvector(data) || isempty(data)
        num_dims = 1;
        dims = length(data);
    else
        num_dims = ndims(data);
        dims = size(data);
    end
    
    dims = fliplr(dims);
    if forceChunked
        max_dims = repmat(unlimited_size, size(dims));
    else
        max_dims = [];
    end
    sid = H5S.create_simple(num_dims, dims, max_dims);
end

%% Do Data Conversions
switch class(data)
    case {'types.untyped.RegionView' 'types.untyped.ObjectView'}
        %will throw errors if refdata DNE.  Caught at NWBData level.
        data = io.getRefData(fid, data);
    case 'logical'
        % encode as int8 values.
        data = int8(data);
    case 'char'
        if isempty(data)
            data = {};
        else
            data = mat2cell(data, size(data, 1));
        end
    case {'cell', 'datetime'}
        if isdatetime(data)
            data = num2cell(data);
        end
        
        for i = 1:length(data)
            data{i} = char(data{i});
        end
end