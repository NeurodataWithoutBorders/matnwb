function [tid, sid, data] = mapData2H5(fid, data, varargin)
%MAPDATA2H5 Convert MATLAB type specifier and data to HDF5 compatible data
%   Given base file_id, type string and data value, returns HDF5 type id, space id,
%   and properly converted data

forceArray = any(strcmp('forceArray', varargin));
forceMatrix = any(strcmp('forceMatrix', varargin));
forceChunked = any(strcmp('forceChunking', varargin));

if iscell(data)
    assert(...
        iscellstr(data) ...
        || all(cellfun('isclass', data, 'datetime')) ...
        || all(cellfun('isclass', data, 'string')) ...
        , 'NWB:MapData:NonCellStr', ['Cell arrays must be cell arrays of character vectors. ' ...
        'Cell arrays of other types are not supported.']);
elseif isstring(data)
    if isscalar(data)
        data = char(data);
    else
        data = cellstr(data);
    end
end

tid = io.getBaseType(class(data));

% max size is always unlimited
unlimited_size = H5ML.get_constant_value('H5S_UNLIMITED');
%determine space size
if ischar(data)
    if ~forceArray && (size(data,1) == 1 || isempty(data))
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
    if ~forceMatrix && (isvector(data) || isempty(data))
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
        %will throw errors if refdata DNE (does not exist).  Caught at NWBData level.
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
            % Check the element type before converting: datetime properties may
            % arrive here as a datetime array (num2cell'd above) or as a cell
            % that already wraps datetime values.
            isDatetimeElement = isdatetime(data{i});
            data{i} = char(data{i});
            if isDatetimeElement
                % Emit a numeric zero offset ("+00:00") instead of the "Z" UTC
                % designator that MATLAB's ISO 8601 format produces for UTC.
                % Both are valid ISO 8601, but Python's datetime.fromisoformat
                % cannot parse "Z" before Python 3.11, which breaks reading
                % MatNWB files in PyNWB on older Python. "+00:00" also matches
                % PyNWB's own output (datetime.isoformat).
                data{i} = regexprep(data{i}, 'Z$', '+00:00');
            end
        end
end