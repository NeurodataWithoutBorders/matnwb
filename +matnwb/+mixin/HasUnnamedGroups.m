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
        % GroupPropertyNames - String array of property names that contain Sets
        GroupPropertyNames (1,:) string
    end
    
    properties (Access = private, Transient)
        % PropertyManager - Manages dynamic properties for this object
        PropertyManager
    end

    % Constructor
    methods
        function obj = HasUnnamedGroups()
            % Create the property manager
            obj.PropertyManager = matnwb.utility.DynamicPropertyManager(obj);
        end
    end
    
    % User-facing methods
    methods
        function add(obj, name, value)
        % add - Add a named data object to an unnamed subgroup

            arguments
                obj (1,1) matnwb.mixin.HasUnnamedGroups
                name (1,1) string
                value % any type
            end

            if obj.nameExists(name)
                throwAsCaller(getNameExistsException(name, obj.TypeName))
            end

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
                identifier = 'NWB:HasUnnamedGroups:AddInvalidType';
                message = ['Object with name `%s` was a "%s", but must be ', ...
                    'one of the following type(s):\n%s\n'];
                allowedTypes = obj.getClassNamesForAllowedGroupTypes();
                allowedTypes = strjoin("  - " + allowedTypes, newline);
                error(identifier, message, name, class(value), allowedTypes)
            end
        end

        function remove(obj, name)
        % remove - remove data object given it's original (actual) name
           
            arguments
                obj (1,1) matnwb.mixin.HasUnnamedGroups
                name (1,1) string % Actual (original) name of a data object
            end

            warnState = warning('off', 'NWB:Set:PropertyNameExistsForEntry');
            warningCleanup = onCleanup(@() warning(warnState));

            for groupName = obj.GroupPropertyNames
                currentSet = obj.(groupName);

                if isa(currentSet, 'types.untyped.Anon')
                    error('Not implemented yet')
                end
                
                % Remove data entry if the name exists in this set
                if currentSet.isKey(name)
                    currentSet.remove(name);
                    return
                else
                    continue
                end
            end

            obj.warnIfNameIsPropertyName(name)
        end
    end
    
    % Method for subclass to initialize the mixin
    methods (Access = protected)
        function setupHasUnnamedGroupsMixin(obj)
            obj.initializeDynamicProperties()
            obj.assignContainedSetCallbackFunctions()
        end
    end
    methods (Access = private)
        function initializeDynamicProperties(obj)
        % initializeDynamicProperties - Init dynamic properties from set entries

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

        function assignContainedSetCallbackFunctions(obj)
            for groupName = obj.GroupPropertyNames
                containerObj = obj.(groupName);
                
                if isa(containerObj, 'types.untyped.Set')
                    containerObj.EntryAddedFunction = ...
                        @(itemName) obj.onSetEntryAdded(itemName, groupName);
                    containerObj.EntryRemovedFunction = ...
                        @(itemName) obj.onSetEntryRemoved(itemName, groupName);
                else
                    warning('NWB:HasUnnamedGroups:NotImplemented', ...
                        'Callback functions are not implemented for Anon types.')
                end
            end
        end
    end

    % Internal methods for managing properties
    methods (Access = private)

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

        function tf = isReservedName(obj, name)
            tf = any( strcmp(obj.GroupPropertyNames, name) );
        end

        function warnIfNameIsPropertyName(obj, name)
        % Issue warning if a given name exists as a property identifier
            if isprop(obj, name)
                for groupName = obj.GroupPropertyNames
                    currentSet = obj.(groupName);
                    
                    try
                        originalName = currentSet.getOriginalName(name);
                    catch
                        continue
                    end
                end

                assert(exist('originalName', 'var'), ...
                    'NWB:HasUnnamedGroups:OriginalNameNotFound', ...
                    ['Internal error. Could not find original name for ', ...
                    'property %s'], name)

                warning('NWB:HasUnnamedGroups:UseOriginalName', ...
                    ['No objects with name "%s" is included in this %s, ', ...
                    'but "%s" is the name of a property corresponding to ', ...
                    'the object with name "%s"'], ...
                    name, ...
                    class(obj), ...
                    name, ...
                    originalName )
            end
        end

        function createDynamicProperty(obj, name, groupName)
        % createDynamicProperty - Add a single dynamic property to the class

            % Get the specified group's Set and a valid MATLAB identifier for
            % the property to create
            setObj = obj.(groupName);
            validName = setObj.getPropertyName(name);

            if obj.isReservedName(validName) % Force non-reserved name
                validName = sprintf('%s_', name);
            end

            % Verify that name only exists in one group
            nameCount = obj.countInstancesOfName(name);
            if nameCount > 1
                setObj.remove(name)
                
                error('NWB:HasUnnamedGroups:DuplicateEntry', ...
                    ['An entry with name `%s` was detected in multiple ', ...
                    'contained groups. Removed entry from group `%s`.'], ...
                    name, groupName)
            end
            
            % Ensure that property does not already exist.
            assert(~isprop(obj, validName), ...
                'NWB:HasUnnamedGroups:DynamicPropertyExists', ...
                'Property with name "%s" already exists', validName)
            
            % Create a getter method that will retrieve the value from the Set
            getMethod = @(~) obj.getDynamicPropertyValueFromSet(name, groupName);
            setMethod = @(nm, value, gNnm) obj.setDynamicPropertyValueToSet(name, value, groupName);
            
            % Add the property using the PropertyManager
            obj.PropertyManager.addProperty(name, ...
                'GetMethod', getMethod, ...
                'SetMethod', setMethod, ...
                'Dependent', true, ...
                'ValidName', validName);
        end

        function deleteDynamicProperty(obj, name)
            % Remove the property using the PropertyManager
            if obj.PropertyManager.existOriginalName(name)
                name = obj.PropertyManager.getPropertyNameForOriginalName(name);
                obj.PropertyManager.removeProperty(name);
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
            
            T = cell(1, numel(obj.GroupPropertyNames) + 1);

            for i = 1:numel(obj.GroupPropertyNames)
                groupName = obj.GroupPropertyNames(i);
                currentSet = obj.(groupName);
                T{i} = currentSet.getPropertyMappingTable();
            end
            
            T{end} = obj.PropertyManager.getPropertyMappingTable();


            T(cellfun('isempty', T)) = [];
            T = cat(1, T{:});

            if ~isempty(T)
                keep = T.ValidIdentifier ~= T.OriginalName;
                T = T(keep, :);
                T = unique(T, "rows");
            end
        end
    end

    % Dynamic property getter methods
    methods (Access = private)
        function value = getDynamicPropertyValueFromSet(obj, name, groupName)
            % Get the value from the Set
            value = obj.(groupName).get(name);
        end
                
        function value = setDynamicPropertyValueToSet(obj, name, value, groupName)
            % Set the value to the Set of the contained subgroup
            obj.(groupName).set(name, value);
        end


        function value = getDynamicPropertyValueFromAnon(obj, groupName)
            value = obj.(groupName).value;
        end
    end

    % Callback methods for types.untyped.Set objects contained in this class
    methods (Access = private)
        function onSetEntryAdded(obj, name, groupName)
        % onSetEntryAdded - Handle entries being added to a contained Set
            obj.createDynamicProperty(name, groupName)
        end

        function onSetEntryRemoved(obj, name, ~)
        % onSetEntryRemoved - Handle entries being removed from a contained Set
            obj.deleteDynamicProperty(name)
        end
    end

    % Utility method that is only accessible from an NwbFile object
    methods (Access = ?NwbFile)
        function T = getRemappedNames(obj)
            T = obj.getTableWithAliasNames();
        end
    end

    % matlab.mixin.CustomDisplay override
    methods (Access = protected)
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
                dynamicPropNames = obj.PropertyManager.getAllPropertyNames();
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
                    keys = setObj.keys();
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
end

function ME = getNameExistsException(name, typeName)
    ME = MException('NWB:HasUnnamedGroups:KeyExists', ...
        'A neurodata object with name `%s` already exists in this `%s`', ...
        name, typeName);
end
