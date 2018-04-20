function checkConstrained(name, namedprops, constrained, val)
if isempty(val)
    return;
end
if ~isa(val, 'containers.Map')
    error('Property `%s` must be a containers.Map.', name);
end

pnames = fieldnames(namedprops);
for i=1:length(pnames)
    nm = pnames{i};
    types.util.checkDtype([name '.' nm], namedprops.(nm), val(nm));
end

constrainedNames = setdiff(keys(val), pnames);
for i=1:length(constrainedNames)
    nm = constrainedNames{i};
    fitsConstraint = false;
    for j=1:length(constrained)
        constr = constrained{j};
        if isa(val(nm), constr)
            fitsConstraint = true;
            break;
        end
    end
    if ~fitsConstraint
        error('Property `%s.%s` does not fit the proper struct constraints.',...
            name, nm);
    end
end
end