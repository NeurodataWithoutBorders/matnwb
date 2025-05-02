classdef HasUnnamedGroups < matlab.mixin.CustomDisplay & dynamicprops & handle
% HasUnnamedGroups - Mixin to simplify access to unnamed subgroup Sets
%
% Overview:
%   Some NWB container types (e.g. ProcessingModule) include unnamed
%   subgroups which can only contain specific types (e.g.
%   NWBDataInterface or DynamicTable).  By default you must say
%     module.nwbdatainterface.get('MyData')
%   This mixin lets you write
%     module.MyData
%
%   To also simplify the adding of new data, this class provides an `add`
%   method. By default you must use:
%     module.nwbdatainterface.set('MyData', dataObject)
%   This mixin lets you write
%     module.add('MyData', dataObject)
%
% Implementation details:
%   - Data elements are added to objects of this class as dynamic properties.
%   - Assign callback functions on Set object to make sure objects of this
%     class are always up-to-date with the included types.untyped.Set objects.
%   - `add` method lets users assign data elements directly without
%     going via the contained Set object
%
% Usage:
%   - Subclasses must implement a static property `GroupPropertyNames`
%     listing the names of the internal Set properties (e.g.
%     {'nwbdatainterface','dynamictable'}).
%     Note: This is added in the matnwb generator pipeline
%
%   - Once applied, any element added to one of those sets is
%     also available directly as a property.
%
% Example:
%   % Before:
%   module = ProcessingModule('mod');
%   module.nwbdatainterface.set('timeseries', types.core.TimeSeries);
%   ts = module.nwbdatainterface.get('timeseries');
%
%   % After using HasUnnamedGroups:
%   module.add('timeseries', types.core.TimeSeries);
%   ts = module.timeseries;

% Note: Subclasses for this mixin might include Anon sets. Currently there
% are no schemas in NWB where Anon sets are used, and this class does not
% currently support contained Anon sets.

% Todo: Add custom footer if any names are aliased to valid matlab names.

% Todo: consider reverse name map, because mapping from actual to valid
% names is ambiguous if the same name is used across groups.
% Or consider one map per contained group

    properties (Abstract, Access = protected, Transient)
        GroupPropertyNames % Cell array of property names that contain Sets
    end
    
    properties (Access = private, Transient)
        % DynamicPropertyMap - A containers.Map (name) -> (meta.DynamicProperty)
        % storing the dynamic property objects for each added dynamic
        % property, accessible by the dynamic property name
        DynamicPropertyMap
        ValidNameMap
    end

    properties (Access = private, Dependent, Transient)
        NumGroups
    end

    methods
        function obj = HasUnnamedGroups()
            obj.DynamicPropertyMap = containers.Map();
            obj.ValidNameMap = containers.Map();
        end
    end
    
    methods
        function add(obj, name, value)
            wasSuccess = false;
            
            for i = 1:numel(obj.GroupPropertyNames)
                thisGroupName = obj.GroupPropertyNames{i};
                thisSet = obj.(thisGroupName);

                if isa(thisSet, 'types.untyped.Anon')
                    error('Not implemented yet')
                end

                try
                    thisSet.set(name, value, ...
                        'FailOnInvalidType', true, ...
                        'FailIfKeyExists', true);
                    wasSuccess = true;
                    break
                catch ME
                    if strcmp(ME.identifier, 'NWB:Set:KeyExists')
                        ME = MException('NWB:HasUnnamedGroupsMixin:KeyExists', ...
                            'A neurodata object with name `%s` already exists in this `%s`', ...
                            name, obj.TypeName);
                        throwAsCaller(ME);
                    elseif strcmp(ME.identifier, 'NWB:Set:FailedValidation')
                        continue
                    else
                        rethrow(ME)
                    end
                end
            end
            if ~wasSuccess
                % If we end up here, the type is invalid.
                identifier = 'NWB:HasUnnamedGroupsMixin:AddInvalidType';
                message = ['Object with name `%s` was a "%s", but must be ', ...
                    'one of the following type(s):\n%s\n'];
                allowedTypes = obj.getClassNamesForAllowedGroupTypes();
                allowedTypes = strjoin("  - " + allowedTypes, newline);
                error(identifier, message, name, class(value), allowedTypes)
            end
        end
   
        function remove(obj, name)
            for i = 1:numel(obj.GroupPropertyNames)
                thisGroupName = obj.GroupPropertyNames{i};
                thisSet = obj.(thisGroupName);
                                
                if isa(thisSet, 'types.untyped.Anon')
                    error('Not implemented yet')
                end
                actualName = obj.ValidNameMap(name);
                if thisSet.isKey(actualName)
                    try
                        thisSet.remove(actualName)
                        break
                    catch ME
                        rethrow(ME)
                    end
                end
            end
        end
    end
    
    methods % Get
        function numGroups = get.NumGroups(obj)
            numGroups = numel(obj.GroupPropertyNames);
        end
    end

    methods (Access = protected)
        function setupHasUnnamedGroupsMixin(obj)
            obj.addDynamicProperties()
            obj.assignContainedSetCallbackFunctions()
        end
    end

    methods (Access = protected) % matlab.mixin.CustomDisplay override
        function groups = getPropertyGroups(obj)
        % getPropertyGroups - Create property groups for display

            standardProps = properties(obj);
            
            % Remove the Set properties that we'll display separately
            toSkip = false(1, length(obj.GroupPropertyNames));
            for i = 1:length(obj.GroupPropertyNames)
                idx = strcmp(standardProps, obj.GroupPropertyNames{i});
                toSkip(idx) = true;
            end
           
            % Todo: Use a nwbPreferences object
            displayPref = getpref('matnwb', 'displaymode', 'groups'); % groups | flat
            
            if strcmp(displayPref, 'groups') % Remove dynamic props
                dynamicPropNames = obj.DynamicPropertyMap.keys();
                for i = 1:length(dynamicPropNames)
                    idx = strcmp(standardProps, dynamicPropNames{i});
                    toSkip(idx) = true;
                end
            end
            standardProps(toSkip) = [];

            % Create a property group for standard properties
            groups = matlab.mixin.util.PropertyGroup(standardProps);
            
            if strcmp(displayPref, 'groups')

                % Create property groups for each Set property
                for i = 1:length(obj.GroupPropertyNames)
                    groupPropName = obj.GroupPropertyNames{i};
                    assert(isprop(obj, groupPropName), ...
                        'Expected "%s" to be a property of class', groupPropName)
                    
                    % Get the Set property
                    setObj = obj.(groupPropName);
                    assert(~isempty(setObj) && isa(setObj, 'types.untyped.Set'), ...
                        'Expected property "%s" to contain a Set', groupPropName)
                    
                    % Get all keys from the Set
                    keys = setObj.keys();
                    validNames = obj.getValidNames(keys); 

                    if ~isempty(keys)
                        propList = cell2struct(setObj.values(), validNames, 2);
                    else
                        propList = string(missing);
                    end
                    
                    % Create a title for this group
                    title = ['<strong>' groupPropName ' elements:</strong>'];
                    
                    % Add this group to the property groups
                    groups(end+1) = matlab.mixin.util.PropertyGroup(propList, title); %#ok<AGROW>
                end
            end
            obj.displayAliasWarning()
        end
    
        function displayAliasWarning(obj)
            allValidNames = string(obj.ValidNameMap.keys());
            allActualNames = string(obj.ValidNameMap.values());

            if ~isequal(allValidNames, allActualNames)
                hasAlias = ~strcmp(allValidNames, allActualNames);
                
                T = table(allValidNames(hasAlias)', allActualNames(hasAlias)', ...
                    'VariableNames', {'ValidName', 'ActualName'} ); %#ok<NASGU>
                nameMap = evalc('disp(T)');

                str = sprintf([...
                    'The following named elements of "%s" are remapped to have valid MATLAB ', ...
                    'names, but will be written to file with their actual names:', ...
                    '\n%s\n'], obj.TypeName, strip(nameMap, 'right'));
            else
                str = '';
            end
            if ~isempty(str)
                warnState = warning('backtrace', 'off');
                resetWarningObj = onCleanup(@() warning(warnState));
                warning(str)
            end
        end
    end

    methods (Access = private)
        function containerObj = getGroupContainer(obj, groupNumber)
            propertyNameForGroup = obj.GroupPropertyNames{groupNumber};
            containerObj = obj.(propertyNameForGroup);
        end
        
        function assignContainedSetCallbackFunctions(obj)
            for i = 1:obj.NumGroups
                propertyNameForGroup = obj.GroupPropertyNames{i};
                containerObj = obj.getGroupContainer(i);
                
                if isa(containerObj, 'types.untyped.Set')
                    containerObj.ItemAddedFunction = ...
                        @(itemName, groupName) obj.onSetItemAdded(itemName, propertyNameForGroup);
                    containerObj.ItemRemovedFunction = ...
                        @(itemName, groupName) obj.onSetItemRemoved(itemName, propertyNameForGroup);
                else
                    warning('NWB:HasUnnamedGroupsMixin:NotImplemented', ...
                        'Callback functions are not implemented for Anon types.')
                end
            end
        end

        function addDynamicProperties(obj)
        % addDynamicProperties - Add dynamic properties for set values

            for i = 1:obj.NumGroups
                groupPropertyName = obj.GroupPropertyNames{i};
                containerObj = obj.getGroupContainer(i);

                if isa(containerObj, 'types.untyped.Set')
                    keys = containerObj.keys();
    
                    for j = 1:numel(keys)
                        obj.addSingleDynamicProperty(keys{j}, groupPropertyName)
                    end
                elseif isa(containerObj, 'types.untyped.Anon')
                    name = containerObj.name;
                    if ~isempty(name)
                        obj.addSingleDynamicProperty(name, groupPropertyName)
                    end
                end
            end
        end

        function pruneDynamicProperties(obj)
            dynamicPropertyNames = obj.DynamicPropertyMap.keys();

            subgroupElementNames = string.empty;

            for i = 1:numel(obj.GroupPropertyNames)
                thisGroupName = obj.GroupPropertyNames{i};
                thisSet = obj.(thisGroupName);
            
                subgroupElementNames = [subgroupElementNames, thisSet.keys]; %#ok<AGROW>
            end
            validMatlabNames = obj.getValidNames(subgroupElementNames);
            removedPropNames = setdiff(dynamicPropertyNames, validMatlabNames);
            
            for i = 1:numel(removedPropNames)
                dynamicPropertyMeta = obj.DynamicPropertyMap(removedPropNames{i});
                delete(dynamicPropertyMeta)
                obj.DynamicPropertyMap.remove(removedPropNames{i})
                obj.ValidNameMap.remove(removedPropNames{i})
            end
        end
    
        function addSingleDynamicProperty(obj, name, groupName)
        % addSingleDynamicProperty - Add a single dynamic property to the class
            matlabValidName = obj.createValidName(name, groupName);
            
            if ~isprop(obj, matlabValidName)
                p = obj.addprop(matlabValidName);
                p.Dependent = true;
                p.GetMethod = @(nm, gnm) obj.getDynamicPropertyValueFromSet(matlabValidName, groupName);
                obj.DynamicPropertyMap(matlabValidName) = p;
                obj.ValidNameMap(matlabValidName) = name;
            else
                error('NWB:HasUnnamedGroupsMixin:DynamicPropertyExists', ...
                    'Dynamic property with name "%s" already exists', matlabValidName)
            end
        end

        function result = getClassNamesForAllowedGroupTypes(obj)
        % getAllowedGroupTypes - Resolve full class names for the allowed group types.
            groupPropertyNames = obj.GroupPropertyNames;
            typeClassNames = schemes.utility.listGeneratedTypes();

            typeClassNamesSplit = split(typeClassNames, '.');
            typeClassNamesShort = typeClassNamesSplit(1,:,end);

            isMatch = ismember(lower(typeClassNamesShort), groupPropertyNames);
            result = typeClassNames(isMatch);
        end
        
        function validName = createValidName(obj, name, groupName)
        % createValidName - Create a valid MATLAB name to using for dynamic
        % property.

            % Make sure the valid name is unique across groups
            if obj.NumGroups > 1
                existingNames = obj.ValidNameMap.values();
                % If the name already exists, prepend the group name to the
                % name
                if any(strcmp(name, existingNames))
                    name = [groupName, '_', name];
                end
            end

            % Make sure the valid name is unique across all other valid names
            isFinished = false;
            suggestedName = name;
            counter = 0;
            while ~isFinished
                suggestedName = matlab.lang.makeValidName(suggestedName);
                if ~any( strcmp(obj.ValidNameMap.keys(), suggestedName))
                    isFinished = true;
                else
                    counter = counter+1;
                    suggestedName = sprintf('%s_%d', name, counter);
                end
            end
            validName = suggestedName;
        end

        function validNames = getValidNames(obj, actualNames)
            allValidNames = obj.ValidNameMap.keys();
            allActualNames = obj.ValidNameMap.values();

            validNames = actualNames;
            for i = 1:numel(actualNames)
                isMatch = strcmp(allActualNames, actualNames{i});
                validNames(i) = allValidNames(isMatch);
            end
        end
    end

    methods % Dynamic property get method
        function value = getDynamicPropertyValueFromSet(obj, name, groupName, varargin)
            actualName = obj.ValidNameMap(name);
            value = obj.(groupName).get(actualName);
        end
                
        function value = getDynamicPropertyValueFromAnon(obj, groupName)
            value = obj.(groupName).value;
        end
    end

    methods (Access = private) % types.untyped.Set callback functions
        function onSetItemAdded(obj, name, groupName)
        % onSetItemAdded - Handle items being added to a contained types.untyped.Set
            obj.addSingleDynamicProperty(name, groupName)
        end

        function onSetItemRemoved(obj, name, groupName)
        % onSetItemRemoved - Handle items being removed from a contained types.untyped.Set

            % Todo: pass name to pruneDynamicProperties
            obj.pruneDynamicProperties()
        end
    end
end
