classdef HasUnnamedGroups < matlab.mixin.CustomDisplay & dynamicprops & handle
% HasUnnamedGroups - Mixin to simplify access to Sets of unnamed subgroups
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
%   method. Using legacy MatNWB syntax, you must use:
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
% are no schemas in NWB where Anon sets are used, and this class therefore 
% does not support contained Anon sets.

    properties (Abstract, Access = protected, Transient)
        GroupPropertyNames (1,:) string % String array of property names that contain Sets
    end
    
    properties (Access = private, Transient)
        % PropertyManager - Manages dynamic properties for this object
        PropertyManager
    end

    methods
        function obj = HasUnnamedGroups()
            % Create the property manager
            obj.PropertyManager = matnwb.utility.DynamicPropertyManager(obj);
        end
    end
    
    methods
        function add(obj, name, value)
        % add - Add a named data object to an un-named subgroup

            if obj.nameExists(name)
                throwAsCaller(getNameExistsException(name, obj.TypeName))
            end

            obj.assertNameNotReserved(name)
                      
            wasSuccess = false;
            for groupName = obj.GroupPropertyNames
                currentSet = obj.(groupName);

                if isa(currentSet, 'types.untyped.Anon')
                    error('Not implemented yet')
                end

                try
                    currentSet.set(name, value, ...
                        'FailOnInvalidType', true);
                    wasSuccess = true;
                    break
                catch ME
                    if strcmp(ME.identifier, 'NWB:Set:FailedValidation')
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

        function value = get(obj, name)
        % get - get a value using it's real name
            for groupName = obj.GroupPropertyNames
                currentSet = obj.(groupName);
                if isKey(currentSet, name)
                    value = currentSet.get(name);
                    return
                end
            end

            % If we end up here, no value exists for the given name
            error('NWB:HasUnnamedGroupsMixin:ObjectDoesNotExist', ...
                'No object with name %s was found in this %s', ...
                name, obj.TypeName)
        end
   
        function remove(obj, name)
        % remove - remove data object given it's (matlab-valid) name
        % todo: name should refer to actual name, not property
        % identifier...
            for groupName = obj.GroupPropertyNames
                currentSet = obj.(groupName);

                if isa(currentSet, 'types.untyped.Anon')
                    error('Not implemented yet')
                end
                
                % Check if the name exists in this set
                if currentSet.isKey(name)
                    currentSet.remove(name);
                    break
                end
                
                % Todo: Should this be a fallback or not? 
                % If the name is a valid property name, try to find the original name
                if isprop(obj, name)
                    % Get the original name from the property manager
                    try
                        originalName = obj.PropertyManager.getOriginalName(name);
                        if currentSet.isKey(originalName)
                            currentSet.remove(originalName);
                            break
                        end
                    catch
                        % If we can't get the original name, continue to the next group
                        continue
                    end
                end
            end
        end
    end

    methods (Access = protected)
        function setupHasUnnamedGroupsMixin(obj)
            obj.initialiseDynamicProperties()
            obj.assignContainedSetCallbackFunctions()
        end
    end

    methods (Access = protected) % matlab.mixin.CustomDisplay override
        function groups = getPropertyGroups(obj)
        % getPropertyGroups - Create property groups for display

            standardProps = properties(obj);
            
            % Remove the Set properties that we'll display separately
            toSkip = false(1, length(obj.GroupPropertyNames));
            
            for groupName = obj.GroupPropertyNames
                idx = strcmp(standardProps, groupName);
                toSkip(idx) = true;
            end
           
            % Todo: Use a nwbPreferences object
            displayPref = getpref('matnwb', 'displaymode', 'groups'); % groups | flat
            
            if strcmp(displayPref, 'groups') % Remove dynamic props
                dynamicPropNames = obj.PropertyManager.getPropertyNames();
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
                for groupName = obj.GroupPropertyNames
                    assert(isprop(obj, groupName), ...
                        'Expected "%s" to be a property of class', groupName)
                    
                    % Get the Set property
                    setObj = obj.(groupName);
                    assert(~isempty(setObj) && isa(setObj, 'types.untyped.Set'), ...
                        'Expected property "%s" to contain a Set', groupName)
                    
                    % Get all keys from the Set
                    keys = setObj.keys(); %todo: property identifiers
                    propNames = cellfun(@(key) setObj.getPropertyName(key), keys, 'uni', 0);
                    
                    % Initialize property list
                    propList = string(missing);

                    if ~isempty(keys)
                        propList = cell2struct(setObj.values(), propNames, 2);
                    end
                    
                    % Create a title for this group
                    title = "<strong>" + groupName + " entries:</strong>";
                    
                    % Add this group to the property groups
                    groups(end+1) = matlab.mixin.util.PropertyGroup(propList, title); %#ok<AGROW>
                end
            end
            obj.displayAliasWarning()
        end
    
        function displayAliasWarning(obj)
        % displayAliasWarning - Display warning if any names have aliases
            T = getTableWithAliasNames(obj);
            if ~isempty(T)
                types.untyped.internal.displayAliasWarning(T, obj.TypeName)
            end
        end
    end

    methods (Access = private)
        function assignContainedSetCallbackFunctions(obj)
            for groupName = obj.GroupPropertyNames
                containerObj = obj.(groupName);
                
                if isa(containerObj, 'types.untyped.Set')
                    containerObj.EntryAddedFunction = ...
                        @(itemName) obj.onSetEntryAdded(itemName, groupName);
                    containerObj.EntryRemovedFunction = ...
                        @(itemName) obj.onSetEntryRemoved(itemName, groupName);
                else
                    warning('NWB:HasUnnamedGroupsMixin:NotImplemented', ...
                        'Callback functions are not implemented for Anon types.')
                end
            end
        end
        
        function assertNameNotReserved(obj, name)
            if any( strcmp(obj.GroupPropertyNames, name) )
                ME = MException(...
                    'NWB:HasUnnamedGroups:ReservedName', ...
                    '`%s` is a reserved name for a %s object. Please use another name.', name, class(obj));
                throwAsCaller(ME)
            end
        end

        function tf = nameExists(obj, name)
        % nameExists - Check if name already exists in subgroup
            tf = false;
            for groupName = obj.GroupPropertyNames
                containerObj = obj.(groupName);
                if containerObj.isKey(name)
                    tf = true;
                    break
                end
            end
        end

        function nameCount = countInstancesOfName(obj, name)
            nameCount = 0;
            
            for groupName = obj.GroupPropertyNames
                containerObj = obj.(groupName);
                if containerObj.isKey(name)
                    nameCount = nameCount + 1;
                end
            end
        end

        function initialiseDynamicProperties(obj)
        % initialiseDynamicProperties - Init dynamic properties from set entries

            for groupName = obj.GroupPropertyNames
                containerObj = obj.(groupName);

                if isa(containerObj, 'types.untyped.Set')
                    keys = containerObj.keys();
                    for j = 1:numel(keys)
                        obj.createDynamicProperty(keys{j}, groupName)
                    end
                elseif isa(containerObj, 'types.untyped.Anon')
                    name = containerObj.name;
                    if ~isempty(name)
                        obj.createDynamicProperty(name, groupName)
                    end
                end
            end
        end

        function createDynamicProperty(obj, name, groupName)
        % createDynamicProperty - Add a single dynamic property to the class
            
            try
                obj.assertNameNotReserved(name)
            catch
                error('NWB:HasUnnamedGroups:CouldNotAddEntry', ...
                    ['Failed to add an entry with the name "%s" as a property ', ...
                    'of this object because "%s" is a reserved name in ', ...
                    '"%s".'], name, name, class(obj))
            end

            % Create a valid MATLAB name
            setObj = obj.(groupName);
            propertyIdentifier = setObj.getPropertyName(name);

            % Check if property already exists
            assert(~isprop(obj, propertyIdentifier), ...
                'NWB:HasUnnamedGroupsMixin:DynamicPropertyExists', ...
                'Property with name "%s" already exists', propertyIdentifier)

            % Verify that name only exists in one group
            nameCount = obj.countInstancesOfName(name);
            if nameCount > 1
                setObj.remove(name)
                
                error('NWB:HasUnnamedGroups:DuplicateEntry', ...
                    ['An entry with name `%s` was detected in multiple ', ...
                    'contained groups. Removed entry from group `%s`.'], ...
                    name, groupName)
            end
            
            % Create a getter method that will retrieve the value from the Set
            getMethod = @(~) obj.getDynamicPropertyValueFromSet(name, groupName);
            
            % Add the property using the PropertyManager
            obj.PropertyManager.addProperty(propertyIdentifier, ...
                'GetMethod', getMethod, ...
                'Dependent', true);
        end

        function deleteDynamicProperty(obj, name)
            % Remove the property using the PropertyManager
            if obj.PropertyManager.hasProperty(name)
                obj.PropertyManager.removeProperty(name);
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

        function T = getTableWithAliasNames(obj)
            
            T = cell(1, numel(obj.GroupPropertyNames));

            for i = 1:numel(obj.GroupPropertyNames)
                groupName = obj.GroupPropertyNames(i);
                currentSet = obj.(groupName);
                T{i} = currentSet.getPropertyMappingTable();
            end

            T(cellfun('isempty', T)) = [];
            T = cat(1, T{:});

            if ~isempty(T)
                keep = T.ValidIdentifier ~= T.OriginalName;
                T = T(keep, :);
            end
        end
    end

    methods % Dynamic property get methods
        function value = getDynamicPropertyValueFromSet(obj, name, groupName)
            % Get the value from the Set
            value = obj.(groupName).get(name);
        end
                
        function value = getDynamicPropertyValueFromAnon(obj, groupName)
            value = obj.(groupName).value;
        end
    end

    methods (Access = private) % types.untyped.Set callback functions
        function onSetEntryAdded(obj, name, groupName)
        % onSetItemAdded - Handle items being added to a contained types.untyped.Set
            obj.createDynamicProperty(name, groupName)
        end

        function onSetEntryRemoved(obj, name, groupName)
        % onSetItemRemoved - Handle items being removed from a contained types.untyped.Set
            obj.deleteDynamicProperty(name)
        end
    end
    
    methods (Access = ?NwbFile)
        function T = getRemappedNames(obj)
            T = obj.getTableWithAliasNames();
        end
    end
end

function ME = getNameExistsException(name, typeName)
    ME = MException('NWB:HasUnnamedGroupsMixin:KeyExists', ...
        'A neurodata object with name `%s` already exists in this `%s`', ...
        name, typeName);
end
