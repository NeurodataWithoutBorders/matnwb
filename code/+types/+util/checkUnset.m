function checkUnset(obj, argin)
    publicProperties = properties(obj);
    objMetaClass = metaclass(obj);
    isHiddenProperty = logical([objMetaClass.PropertyList.Hidden]);
    hiddenProperties = {objMetaClass.PropertyList(isHiddenProperty).Name};
    allProperties = union(publicProperties, hiddenProperties);
    anonNames = {};
    for i = 1:length(allProperties)
        p = obj.(allProperties{i});
        if isa(p, 'types.untyped.Anon')
            anonNames = [anonNames;{p.name}];
        elseif isa(p, 'types.untyped.Set')
            anonNames = [anonNames;keys(p) .'];
        end
    end
    dropped = setdiff(argin, union(allProperties, anonNames));
    if ~isempty(dropped)
        warning('NWB:CheckUnset:InvalidProperties', ...
            'Unexpected properties {%s} for instance of type "%s".', ...
            misc.cellPrettyPrint(dropped), class(obj));
    end
end