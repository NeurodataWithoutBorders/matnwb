function val = correctType(val, type)
%CORRECTTYPE upcasts if type is smaller than minimum
%   Will error if type is simply incompatible
%   Will throw if casting is impossible

%check different types and correct
switch (type)
    case {'float64' 'float32' 'float'}
        if ~isfloat(val)
            val = double(val);
        end
    case 'int'
        if ~isinteger(val)
            val = int64(val);
        end
    case 'uint'
        if ~isinteger(val)
            val = uint64(val);
        end
    case 'numeric'
        if ~isnumeric(val)
            val = double(val);
        end
    case 'logical'
        if ~islogical(val)
            val = logical(val);
        end
end

%check different types sizes and upcast to meet minimum (if applicable)
if strcmp(type, 'float64') && strcmp(class(val), 'single')
    val = double(val);
if (~strcmp(type, 'int') && startsWith(type, 'int')) ||...
        (~strcmp(type, 'uint') && startsWith(type, 'uint'))
    pattern = 'int%d';
    if startsWith(type, 'u')
        pattern = ['u' pattern];
    end
    typsz = sscanf(type, pattern);
    valsz = sscanf(class(val), pattern);
    
    if valsz < typsz
       val = eval([type '(val)']); 
    end
end
end