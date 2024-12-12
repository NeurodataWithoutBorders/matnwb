function allProps = mergeProps(props, superClassProps)
% merge_props - Merge maps containing props info for class and it's superclasses

    allPropsCell = [{props}, superClassProps];
    allProps = containers.Map();

    % Start from most remote ancestor and work towards current class.
    % Important to go in this order because subclasses can override
    % properties, and we need to keep the property definition for the superclass
    % that is closest to the current class or the property definition for the 
    % class itself in the final map
    for i = numel(allPropsCell):-1:1
        superPropNames = allPropsCell{i}.keys;
        for jProp = 1:numel(superPropNames)
            allProps(superPropNames{jProp}) = allPropsCell{i}(superPropNames{jProp});
        end
    end
end
