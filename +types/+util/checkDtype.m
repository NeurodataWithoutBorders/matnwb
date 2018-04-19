function checkDtype(name, type, val)
%ref
%any, double, int/uint, char
errmsg = ['Property `' name '` must be a ' type '.'];
if isempty(val)
    return;
end
switch type
    case 'double'
        if ~isnumeric(val)
            error(errmsg);
        end
    case {'int64' 'uint64'}
        if ~isinteger(val)
            error(errmsg);
        end
        
        if strcmp(types, 'uint64') && val < 0
            error('Property `%s` must be greater than zero.', name);
        end
    case 'char'
        if ~ischar(val)
            error(errmsg);
        end
    otherwise %class or ref to class
        if ~iscell(val)
            val = {val};
        end
        for i=1:length(val)
            subval = val{i};
            if ~isa(subval, type)
                error(errmsg);
            end
        end
end

end