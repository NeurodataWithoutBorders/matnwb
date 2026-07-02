function result = collectConstantPropertiesAcrossHierarchy(className, propertyName)
% collectConstantPropertyAcrossHierarchy - Collect constant property values
% across class hierarchy
%
% Syntax:
%   groupTypes = collectConstantPropertiesAcrossHierarchy(nwbTypeName) 
%   This function retrieves property names of unnamed groups associated with 
%   the specified NWB type name, traversing the class hierarchy to also include
%   property names of unnamed groups for parent types.
%
% Input Arguments:
%   nwbTypeName (1,1) string - The name of the NWB type for which property 
%   names of unnamed groups are to be retrieved.
%
% Output Arguments:
%   groupPropertyNames - An array of property names of unnamed groups 
%   associated with the specified NWB type.
%
% Assumptions:
%   1. Class name is the name of a generated neurodata type
%   2. A parent neurodata type (superclass) is always defined as the first
%      superclass if a class inherits from multiple classes.
    
    arguments
        className (1,1) string
        propertyName (1,1) string
    end

    result = string.empty; % Initialize an empty cell array
    currentType = className; % Start with the specific type

    % Iterate over class and superclasses to detect property names for 
    % unnamed groups across the type hierarchy.
    while ~strcmp(currentType, 'types.untyped.MetaClass')
        
        % Use MetaClass information to get class information
        metaClass = meta.class.fromName(currentType);
        
        % Get value of GroupPropertyNames if this class is a subclass of
        % the HasUnnamedGroups subclass.
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
