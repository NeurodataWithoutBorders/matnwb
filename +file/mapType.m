function matlabType = mapType(dtype)
%MAPTYPE
% converts dtype name to type name.  If struct, then returns a struct of mapped types
% all this does is narrow the possible range of names per type.

if isempty(dtype) || (ischar(dtype) && any(strcmpi({'None', 'any'}, dtype)))
    matlabType = 'any';
    return;
end

if iscell(dtype)
    %compound type
    matlabType = struct();
    numTypes = length(dtype);
    for i=1:numTypes
        typeMap = dtype{i};
        typeName = typeMap('name');
        type = file.mapType(typeMap('dtype'));
        matlabType.(typeName) = type;
    end
    return;
end

if isa(dtype, 'containers.Map')
    matlabType = dtype;
    return;
end

assert(ischar(dtype), 'NWB:MapType:InvalidDtype', ...
    'schema attribute `dtype` returned in unsupported type `%s`', class(dtype));

switch dtype
    case {'text', 'utf', 'utf8', 'utf-8', 'ascii', 'bytes'}
        matlabType = 'char';
    case 'bool'
        matlabType = 'logical';
    case 'isodatetime'
        matlabType = 'datetime';
    case {'float', 'float32'}
        matlabType = 'single';
    case 'float64'
        matlabType = 'double';
    case 'long'
        matlabType = 'int64';
    case 'int'
        matlabType = 'int8';
    case 'short'
        matlabType = 'int16';
    otherwise
        matlabType = dtype;
end