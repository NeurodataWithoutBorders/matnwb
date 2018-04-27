% converts dtype name to type name.  If struct, then returns a struct of mapped types
function dt = mapType(dtype)
dt = [];
if isempty(dtype) || any(strcmp({'None', 'any'}, dtype))
    dt = 'any';
elseif isa(dtype, 'java.util.ArrayList')
    %compound type
    dt = struct();
    len = dtype.size();
    dtypeiter = dtype.iterator();
    doc = cell(len,1);
    for i=1:len
        subdtype = dtypeiter.next();
        subtypeName = subdtype.get('name');
        subtype = file.mapType(subdtype.get('dtype'));
        subdoc = subdtype.get('doc');
        
        dt.(subtypeName) = subtype;
        doc{i} = [subtypeName ': ' subdoc];
    end
elseif isa(dtype, 'java.util.HashMap')
    dt = dtype;
elseif startsWith(dtype, 'float') || strcmp(dtype, 'number')
    dt = 'double';
elseif any(strcmp({'ascii', 'str', 'text', 'utf8'}, dtype))
    dt = 'char';
elseif startsWith(dtype, 'int')
    dt = 'int64';
elseif startsWith(dtype, 'uint')
    dt = 'uint64';
end

end