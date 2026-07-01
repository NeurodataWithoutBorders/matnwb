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
        message = sprintf('Unexpected properties {%s} for instance of type "%s".', ...
            misc.cellPrettyPrint(dropped), class(obj));

        target = matnwb.common.validation.internal.validationTarget();
        if ~isempty(target)
            message = sprintf('%s at file location "%s".', ...
                message(1:end-1), target.Path);
        end

        message = sprintf('%s\nNB: The properties in question were dropped.', message);

        if matnwb.common.validation.isReadContext()
            message = sprintf(['%s\nConsider checking the schema version of the file ' ...
                'with `util.getSchemaVersion(filename)` and comparing with the ' ...
                'YAML namespace version present in nwb-schema/core/nwb.namespace.yaml'], ...
                message);
        end

        warning('NWB:CheckUnset:InvalidProperties', '%s', message)
    end
end
