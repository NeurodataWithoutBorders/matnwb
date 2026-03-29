function classprops = filterClassPropsForCodegen(classprops, namespace)
% filterClassPropsForCodegen - Remove redundant generated properties.

    classprops = removeRedundantTypedDatasetAttributeHoists(classprops, namespace);
end

function classprops = removeRedundantTypedDatasetAttributeHoists(classprops, namespace)
    propertyNames = keys(classprops);
    toRemove = {};

    for iProp = 1:length(propertyNames)
        propertyName = propertyNames{iProp};
        prop = classprops(propertyName);
        if ~isa(prop, 'file.Attribute') || isempty(prop.dependent) || ~prop.dependent_typed
            continue;
        end

        if ~isKey(classprops, prop.dependent)
            continue;
        end

        parentProp = classprops(prop.dependent);
        if ~isa(parentProp, 'file.Dataset') || isempty(parentProp.type)
            continue;
        end

        childNamespace = namespace.getNamespace(parentProp.type);
        if isempty(childNamespace)
            continue;
        end

        % Skip hoisting when the child typed dataset already exposes the
        % attribute as part of its own public API.
        isHiddenOnChild = file.internal.isPropertyHidden(prop, parentProp.type, childNamespace);
        if ~isHiddenOnChild
            toRemove{end+1} = propertyName; %#ok<AGROW>
        end
    end

    if ~isempty(toRemove)
        remove(classprops, unique(toRemove));
    end
end
