function val = correctType(val, type, allowDowncast)
%CORRECTTYPE upcasts if type is smaller than minimum
%   Will error if type is simply incompatible
%   Will throw if casting is impossible

%check different types and correct

if startsWith(type, 'float') && ~isfloat(val)
    val = double(val);
elseif startsWith(type, 'int') && ~isinteger(val)
    val = int64(val);
elseif startsWith(type, 'uint') && ~isinteger(val)
    val = uint64(val);
elseif strcmp(type, 'numeric') && ~isnumeric(val)
    val = double(val);
elseif strcmp(type, 'bool') && ~islogical(val)
    val = logical(val);
end

%check different types sizes and upcast to meet minimum (if applicable)
if any(strcmp(type, {'float64' 'float32'})
    if issingle(val)
        val = double(val);
    elseif allowDowncast && strcmp(type, 'float32')
        val = single(val);
    end
elseif (~strcmp(type, 'int') && startsWith(type, 'int')) ||...
        (~strcmp(type, 'uint') && startsWith(type, 'uint'))
    pattern = 'int%d';
    if startsWith(type, 'u')
        pattern = ['u' pattern];
    end
    typsz = sscanf(type, pattern);
    valsz = sscanf(class(val), pattern);
    
    if valsz < typsz || (nargin > 2 && allowDowncast)
        val = eval([type '(val)']);
    end
end
end