function result = collectConstantPropertiesAcrossHierarchy(className, propertyName)
% collectConstantPropertiesAcrossHierarchy - Collect constant property values
% across a generated neurodata class hierarchy.
%
% Syntax:
%   result = collectConstantPropertiesAcrossHierarchy(className, propertyName)
%   This function retrieves private constant string-list metadata declared on
%   a generated neurodata type and its generated parent types.
%
% Input Arguments:
%   className (1,1) string - The full class name of a generated neurodata type.
%   propertyName (1,1) string - The constant property to collect.
%
% Output Arguments:
%   result - A string array containing the aggregated property values.
%
% Assumptions:
%   1. Class name is the name of a generated neurodata type
%   2. A parent neurodata type (superclass) is always defined as the first
%      superclass if a class inherits from multiple classes.
    
    arguments
        className (1,1) string
        propertyName (1,1) string
    end

    result = string.empty(1, 0);
    currentType = className;

    % NWB parent type inheritance is represented by the first superclass.
    % Additional superclasses are mixins and implementation base classes.
    while ~strcmp(currentType, 'types.untyped.MetaClass')
        
        metaClass = meta.class.fromName(currentType);
        
        isProp = strcmp({metaClass.PropertyList.Name}, propertyName);
        if any(isProp)
            result = [result, ...
                string(metaClass.PropertyList(isProp).DefaultValue)]; %#ok<AGROW>
        end
    
        if isempty(metaClass.SuperclassList)
            break % Reached the base type
        end

        % Get superclass for next iteration. NWB parent type should 
        % always be the first superclass in the list
        currentType = metaClass.SuperclassList(1).Name;
    end

    result = unique(result, 'stable');
end
