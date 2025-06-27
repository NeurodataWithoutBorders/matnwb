classdef DynamicPropertyManager < handle
% DynamicPropertyManager - Manages dynamic properties for a target object
%   This class provides a consistent interface for creating, accessing,
%   and removing dynamic properties on a target object.
    
    properties (Access = private)
        TargetObject            % The object to manage dynamic properties for
        DynamicPropertyMap      % A containers.Map (name) -> (meta.DynamicProperty)
        NameRegistry            % NameRegistry instance for name mapping
    end
    
    properties %(SetAccess = private)
        PropertyAddedFunction   % Function handle called when a property is added
        PropertyRemovedFunction % Function handle called when a property is removed
    end
    
    methods
        function obj = DynamicPropertyManager(targetObject, nameRegistry, propArgs)
            % Create a new DynamicPropertyManager for the target object
            arguments
                targetObject (1,1) dynamicprops
                nameRegistry (1,1) matnwb.utility.NameRegistry = matnwb.utility.NameRegistry
                propArgs.propertyAddedFunction function_handle = function_handle.empty
                propArgs.propertyRemovedFunction function_handle = function_handle.empty
            end
            
            obj.TargetObject = targetObject;
            obj.DynamicPropertyMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.NameRegistry = nameRegistry;
            obj.PropertyAddedFunction = propArgs.propertyAddedFunction;
            obj.PropertyAddedFunction = propArgs.propertyRemovedFunction;
        end

        function metaProperty = addProperty(obj, originalName, options)
            % Add a dynamic property to the target object
            arguments
                obj matnwb.utility.DynamicPropertyManager
                originalName (1,1) string
                options.GetMethod function_handle = function_handle.empty
                options.SetMethod function_handle = function_handle.empty
                options.Dependent (1,1) logical = false
            end
                        
            % Get or create valid name
            if obj.NameRegistry.existOriginalName(originalName)
                validName = obj.NameRegistry.getValidName(originalName);
            else
                validName = obj.NameRegistry.addMapping(originalName);
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
                        
            % Determine if this is a valid name or original name

            % Todo: There is an ambiguity here. A name could be added which
            % is has a valid equivalent, and then the valid equivalent is
            % added...
            if obj.NameRegistry.existValidName(name)
                validName = name;
                originalName = obj.NameRegistry.getOriginalName(validName);
            elseif obj.NameRegistry.existOriginalName(name)
                originalName = name;
                validName = obj.NameRegistry.getValidName(originalName);
            else
                error('NWB:DynamicPropertyManager:UnknownProperty', ...
                    'No property with name "%s" exists', name);
            end
            
            % Check if the property exists in our map
            assert(obj.DynamicPropertyMap.isKey(validName), ...
                'NWB:DynamicPropertyManager:PropertyNotManaged', ...
                'Property "%s" is not managed by this DynamicPropertyManager', validName);
            
            % Get the property metadata
            propMeta = obj.DynamicPropertyMap(validName);
            
            % Delete the property
            delete(propMeta);
            
            % Remove from our maps
            obj.DynamicPropertyMap.remove(validName);
            obj.NameRegistry.removeMapping(validName);
            
            % Call the callback if set
            if ~isempty(obj.PropertyRemovedFunction)
                obj.PropertyRemovedFunction(originalName);
            end
        end
        
        function names = getPropertyNames(obj)
            % Get all property names
            names = obj.DynamicPropertyMap.keys();
        end
                
        function names = getOriginalNames(obj)
            % Get all property names
            names = obj.NameRegistry.getAllOriginalNames();
        end
        
        function tf = hasProperty(obj, name)
            % Check if a property exists
            arguments
                obj matnwb.utility.DynamicPropertyManager
                name (1,1) string
            end
            % Todo: should this method also check original names?
            tf = obj.NameRegistry.existValidName(name) || ...
                 obj.NameRegistry.existOriginalName(name);
        end

        function originalName = getOriginalName(obj, validName)
            originalName = obj.NameRegistry.getOriginalName(validName);
        end

        function tf = existOriginalName(obj, originalName)
            tf = obj.NameRegistry.existOriginalName(originalName);
        end
        
        function propertyName = getPropertyNameFromOriginalName(obj, originalName)
            propertyName = obj.NameRegistry.getValidName(originalName);
        end

        function T = getPropertyMappingTable(obj)
            % Get a table showing property mappings
            T = obj.NameRegistry.getNameMappingTable();
        end
    end
end
