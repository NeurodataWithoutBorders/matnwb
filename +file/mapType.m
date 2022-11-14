function dt = mapType(dtype)
%MAPTYPE
% converts dtype name to type name.  If struct, then returns a struct of mapped types
% all this does is narrow the possible range of names per type.

if isempty(dtype) || (ischar(dtype) && any(strcmpi({'None', 'any'}, dtype)))
    dt = 'any';
    return;
end

if iscell(dtype)
    %compound type
    dt = struct();
    numTypes = length(dtype);
    for i=1:numTypes
        typeMap = dtype{i};
        typeName = typeMap('name');
        type = file.mapType(typeMap('dtype'));
        dt.(typeName) = type;
    end
    return;
end

if isa(dtype, 'containers.Map')
    dt = dtype;
    return;
end

assert(ischar(dtype), 'NWB:MapType:InvalidDtype', ...
    'schema attribute `dtype` returned in unsupported type `%s`', class(dtype));

switch dtype
    case {'text', 'utf', 'utf8', 'utf-8', 'ascii', 'bytes'}
        dt = 'char';
    case 'bool'
        dt = 'logical';
    case 'isodatetime'
        dt = 'datetime';
    case {'float', 'float32'}
        dt = 'single';
    case 'float64'
        dt = 'double';
    case 'long'
        dt = 'int64';
    case 'int'
        dt = 'int32';
    case 'short'
        dt = 'int16';
    otherwise
        dt = dtype;
end