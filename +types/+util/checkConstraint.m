function checkConstraint(pname, name, namedprops, constrained, val)
if isempty(val)
    return;
end

names = fieldnames(namedprops);
if any(strcmp(name, names))
    types.util.checkDtype([pname '.' name], namedprops.(name), val);
else
    for i=1:length(constrained)
        allowedType = constrained{i};
        if isa(val, allowedType)
            return;
        end
    end
    error(['Property `%s.%s` should be one of type(s) {' ...
        misc.cellPrettyPrint(constrained) '}.']...
        ,pname, name);
end
end