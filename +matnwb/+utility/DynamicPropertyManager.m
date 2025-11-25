classdef DynamicPropertyManager < handle
% DynamicPropertyManager - Manages dynamic properties for a target object

%   - This class provides a consistent interface for creating and removing
%     dynamic properties on a target object.
%   - It additionally provides an internal name registry, to keep track of
%     original names of properties that might not be valid MATLAB
%     identifiers. When adding a property with a name which is not a valid
%     MATLAB identifier, a valid alias is registered and used as a name for
%     the dynamic property.
%
%   Used by types.untyped.Set and matnwb.mixin.HasUnnamedGroups to
%   allow users to access neurodata types stored in object properties of
%   other neurodata types through dot-syntax.
    
    properties (Access = private)
        TargetObject            % The object to manage dynamic properties for
        DynamicPropertyMap      % A containers.Map (name) -> (meta.DynamicProperty)
        NameRegistry            % NameRegistry instance for name mapping
    end
    
    properties (SetAccess = immutable)
        PropertyAddedFunction   % Function handle called when a property is added
        PropertyRemovedFunction % Function handle called when a property is removed
    end
    
    methods
        function obj = DynamicPropertyManager(targetObject, nameRegistry, propArgs)
            % Create a new DynamicPropertyManager for the target object
            arguments
                targetObject dynamicprops % Note: No size constraint because types.untyped.Set (a possible input type) overrides size and has an irregular size.
                nameRegistry (1,1) matnwb.utility.NameRegistry = matnwb.utility.NameRegistry
                propArgs.propertyAddedFunction function_handle = function_handle.empty
                propArgs.propertyRemovedFunction function_handle = function_handle.empty
            end
            
            obj.TargetObject = targetObject;
            obj.DynamicPropertyMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.NameRegistry = nameRegistry;
            obj.PropertyAddedFunction = propArgs.propertyAddedFunction;
            obj.PropertyRemovedFunction = propArgs.propertyRemovedFunction;
        end

        function metaProperty = addProperty(obj, originalName, options)
            % Add a dynamic property to the target object
            arguments
                obj matnwb.utility.DynamicPropertyManager
                originalName (1,1) string
                options.GetMethod function_handle = function_handle.empty
                options.SetMethod function_handle = function_handle.empty
                options.Dependent (1,1) logical = false
                options.ValidName (1,1) string = missing
            end
            
            % Get or create valid name
            if ~ismissing(options.ValidName)
                validName = options.ValidName;
                obj.NameRegistry.addMapping(originalName, validName);
            else
                if obj.NameRegistry.existOriginalName(originalName)
                    validName = obj.NameRegistry.getValidName(originalName);
                else
                    validName = obj.NameRegistry.addMapping(originalName);
                end
            end

            % Check if property already exists
            assert(~isprop(obj.TargetObject, validName), ...
                'NWB:DynamicPropertyManager:PropertyExists', ...
                'Property "%s" already exists on target object', validName);
            
            % Add the property
            metaProperty = obj.TargetObject.addprop(validName);
            
            % Set get/set methods if provided
            if ~isempty(options.GetMethod)
                metaProperty.GetMethod = options.GetMethod;
            end
            
            if ~isempty(options.SetMethod)
                metaProperty.SetMethod = options.SetMethod;
            end

            metaProperty.Dependent = options.Dependent;
            
            % Store the property metadata
            obj.DynamicPropertyMap(validName) = metaProperty;
            
            % Call the callback if set
            if ~isempty(obj.PropertyAddedFunction)
                obj.PropertyAddedFunction(originalName);
            end

            if ~nargout
                clear metaProperty
            end
        end
        
        function removeProperty(obj, name)
            % Remove a dynamic property from the target object
            arguments
                obj matnwb.utility.DynamicPropertyManager
                name (1,1) string
            end
            
            % Try to remove entry assuming original name is given, fall back 
            % to removing entry using property name.
            if obj.existOriginalName(name)
                originalName = name;
                propertyName = obj.getPropertyNameForOriginalName(originalName);
            elseif obj.existPropertyName(name)
                propertyName = name;
                originalName = obj.getOriginalNameForPropertyName(propertyName);
            else
                error('NWB:DynamicPropertyManager:UnknownProperty', ...
                    'No property with name "%s" exists', name);
            end
            
            % Check if the property exists in our map
            assert(obj.DynamicPropertyMap.isKey(propertyName), ...
                'NWB:DynamicPropertyManager:PropertyNotManaged', ...
                'Property "%s" is not managed by this DynamicPropertyManager', propertyName);
            
            % Get the property metadata
            propMeta = obj.DynamicPropertyMap(propertyName);
            
            % Delete the property
            delete(propMeta);
            
            % Remove from internal maps
            obj.DynamicPropertyMap.remove(propertyName);
            obj.NameRegistry.removeMapping(propertyName);
            
            % Call the callback if set
            if ~isempty(obj.PropertyRemovedFunction)
                obj.PropertyRemovedFunction(originalName);
            end
        end
        
        function originalName = getOriginalNameForPropertyName(obj, propertyName)
            originalName = obj.NameRegistry.getOriginalName(propertyName);
        end

        function propertyName = getPropertyNameForOriginalName(obj, originalName)
            propertyName = obj.NameRegistry.getValidName(originalName);
        end

        function count = getPropertyCount(obj)
            count = obj.DynamicPropertyMap.Count;
        end

        function names = getAllPropertyNames(obj)
            % Get all property names
            names = obj.DynamicPropertyMap.keys();
        end

        function names = getAllOriginalNames(obj)
            % Get all property names
            names = obj.NameRegistry.getAllOriginalNames();
        end

        function tf = existPropertyName(obj, propertyName)
            arguments
                obj matnwb.utility.DynamicPropertyManager
                propertyName (1,1) string
            end
            tf = obj.NameRegistry.existValidName(propertyName);
        end

        function tf = existOriginalName(obj, originalName)
            arguments
                obj matnwb.utility.DynamicPropertyManager
                originalName (1,1) string
            end
            tf = obj.NameRegistry.existOriginalName(originalName);
        end

        function T = getPropertyMappingTable(obj)
            % Get a table showing property mappings
            T = obj.NameRegistry.getNameMappingTable();
        end
    end
end
