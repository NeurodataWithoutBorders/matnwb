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

    properties (Abstract, Access = protected, Transient)
        GroupPropertyNames (1,:) string % String array of property names that contain Sets
    end
    
    properties (Access = private, Transient)
        % DynamicPropertyMap - A containers.Map (name) -> (meta.DynamicProperty)
        % storing the dynamic property objects for each added dynamic
        % property, accessible by the dynamic property name
        DynamicPropertyMap
        
        % ValidNameMaps - A containers.Map (groupName) -> (containers.Map)
        % Each group has its own ValidNameMap that maps valid MATLAB names to 
        % actual NWB names
        ValidNameMaps
    end

    methods
        function obj = HasUnnamedGroups()
            obj.DynamicPropertyMap = containers.Map();
            obj.ValidNameMaps = containers.Map();
        end
    end
    
    methods
        function add(obj, name, value)
        % add - Add a named data object to an un-named subgroup

            if obj.nameExists(name)
                throwAsCaller( getNameExistsException(name, obj.TypeName) )
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
            for groupName = obj.GroupPropertyNames
                currentSet = obj.(groupName);

                if isa(currentSet, 'types.untyped.Anon')
                    error('Not implemented yet')
                end
               
                if obj.ValidNameMaps(groupName).isKey(name)
                    actualName = obj.getActualNameFromValidName(name, groupName);
                        
                    if currentSet.isKey(actualName)
                        currentSet.remove(actualName);
                        break
                    end
                end
            end
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
            
            for groupName = obj.GroupPropertyNames
                idx = strcmp(standardProps, groupName);
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
                for groupName = obj.GroupPropertyNames
                    assert(isprop(obj, groupName), ...
                        'Expected "%s" to be a property of class', groupName)
                    
                    % Get the Set property
                    setObj = obj.(groupName);
                    assert(~isempty(setObj) && isa(setObj, 'types.untyped.Set'), ...
                        'Expected property "%s" to contain a Set', groupName)
                    
                    % Get all keys from the Set
                    keys = setObj.keys();
                    validNames = obj.getValidNamesFromActualNames(keys, groupName); 

                    % Initialize property list
                    propList = string(missing);

                    if ~isempty(keys)
                        propList = cell2struct(setObj.values(), validNames, 2);
                    end
                    
                    % Create a title for this group
                    title = "<strong>" + groupName + " elements:</strong>";
                    
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
                nameMap = evalc('disp(T)');

                str = sprintf([...
                    'The following named elements of "%s" are remapped to have valid MATLAB ', ...
                    'names, but will be written to file with their actual names:', ...
                    '\n%s\n'], obj.TypeName, strip(nameMap, 'right'));

                warnState = warning('backtrace', 'off');
                resetWarningObj = onCleanup(@() warning(warnState));
                warning(str)
            end
        end
    end

    methods (Access = private)
        function assignContainedSetCallbackFunctions(obj)
            for groupName = obj.GroupPropertyNames
                containerObj = obj.(groupName);
                
                if isa(containerObj, 'types.untyped.Set')
                    containerObj.ItemAddedFunction = ...
                        @(itemName) obj.onSetItemAdded(itemName, groupName);
                    containerObj.ItemRemovedFunction = ...
                        @(itemName) obj.onSetItemRemoved(itemName, groupName);
                else
                    warning('NWB:HasUnnamedGroupsMixin:NotImplemented', ...
                        'Callback functions are not implemented for Anon types.')
                end
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

        function addDynamicProperties(obj)
        % addDynamicProperties - Add dynamic properties for set values

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
            matlabValidName = obj.createValidName(name, groupName);
            
            assert( ~isprop(obj, matlabValidName), ...
                'NWB:HasUnnamedGroupsMixin:DynamicPropertyExists', ...
                'Dynamic property with name "%s" already exists', matlabValidName )

            p = obj.addprop(matlabValidName);
            p.Dependent = true;
            p.GetMethod = @(nm, gnm) obj.getDynamicPropertyValueFromSet(matlabValidName, groupName);
            obj.DynamicPropertyMap(matlabValidName) = p;
            
            % Create ValidNameMap for this group if it doesn't exist
            if ~obj.ValidNameMaps.isKey(groupName)
                obj.ValidNameMaps(groupName) = containers.Map();
            end
            
            % Add mapping to the group's ValidNameMap
            nameMapForGoup = obj.ValidNameMaps(groupName);
            nameMapForGoup(matlabValidName) = name; %#ok<NASGU>
        end

        function deleteDynamicProperty(obj, name, groupName)
            dynamicPropertyMeta = obj.DynamicPropertyMap(name);
            delete(dynamicPropertyMeta)
            obj.DynamicPropertyMap.remove(name);

            if obj.ValidNameMaps.isKey(groupName) && obj.ValidNameMaps(groupName).isKey(name)
                obj.ValidNameMaps(groupName).remove(name);
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
        % createValidName - Create a valid MATLAB name to use for dynamic property.

            % Make sure the valid name is unique across groups
            if numel(obj.GroupPropertyNames) > 1
                % Check if the name already exists in any other group
                existingNames = [];
                allGroupNames = obj.ValidNameMaps.keys();
                for i = 1:numel(allGroupNames)
                    currentGroupName = allGroupNames{i};
                    if ~strcmp(currentGroupName, groupName) && obj.ValidNameMaps.isKey(currentGroupName)
                        currentGroupMap = obj.ValidNameMaps(currentGroupName);
                        if ~isempty(currentGroupMap)
                            existingNames = [existingNames, currentGroupMap.values()]; %#ok<AGROW>
                        end
                    end
                end
                
                % If the name already exists in another group, prepend the group name
                if any(strcmp(name, existingNames))
                    name = sprintf('%s_%s', groupName, name);
                end
            end

            % Make sure the valid name is unique across all dynamic properties
            isFinished = false;
            suggestedName = name;
            counter = 0;
            while ~isFinished
                suggestedName = matlab.lang.makeValidName(suggestedName);
                if ~isprop(obj, suggestedName)
                    isFinished = true;
                else
                    counter = counter+1;
                    suggestedName = sprintf('%s_%d', name, counter);
                end
            end
            validName = suggestedName;
        end

        function validNames = getValidNamesFromActualNames(obj, actualNames, groupName)
            
            validNames = cell(size(actualNames));
            if isempty(actualNames); return; end

            validNameMap = obj.ValidNameMaps(groupName);
            
            % Get all valid names and actual names for this group
            allValidNames = validNameMap.keys();
            allActualNames = validNameMap.values();
                        
            % Check each group's ValidNameMap
            for i = 1:numel(actualNames)

                % Find the matching valid name
                isMatch = strcmp(allActualNames, actualNames{i});
                if any(isMatch)
                    validNames{i} = allValidNames{isMatch};
                end
            end
        end
        
        function actualName = getActualNameFromValidName(obj, validName, groupName)
        % getActualNameFromValidName - Reverse-map actual name from valid name
            
            validNameMap = obj.ValidNameMaps(groupName);
            
            assert(validNameMap.isKey(validName), ...
                'Expected "%s" to be present in group "%s"', ...
                validName, groupName)

            actualName = validNameMap(validName);
        end
    
        function T = getTableWithAliasNames(obj)
            allValidNames = string.empty;
            allActualNames = string.empty;
            
            % Collect all valid and actual names from all groups
            groupNames = obj.ValidNameMaps.keys();
            for i = 1:numel(groupNames)
                groupName = groupNames{i};

                validNameMap = obj.ValidNameMaps(groupName);
                
                if ~isempty(validNameMap)
                    allValidNames = [allValidNames, string(validNameMap.keys())]; %#ok<AGROW>
                    allActualNames = [allActualNames, string(validNameMap.values())]; %#ok<AGROW>
                end
            end

            if ~isequal(allValidNames, allActualNames)
                hasAlias = ~strcmp(allValidNames, allActualNames);
                
                T = table(allValidNames(hasAlias)', allActualNames(hasAlias)', ...
                    'VariableNames', {'ValidName', 'ActualName'} ); %#ok<NASGU>
            else
                T = table.empty;
            end
        end
    
    end

    methods % Dynamic property get methods
        function value = getDynamicPropertyValueFromSet(obj, name, groupName)
            % Get the actual name from the group's ValidNameMap
            
            %Assume actual name is the same as the valid name.
            actualName = name;
            if obj.ValidNameMaps.isKey(groupName) ...
                    && obj.ValidNameMaps(groupName).isKey(name)
                nameMapForGroup = obj.ValidNameMaps(groupName);
                actualName = nameMapForGroup(name);
            end
            value = obj.(groupName).get(actualName);
        end
                
        function value = getDynamicPropertyValueFromAnon(obj, groupName)
            value = obj.(groupName).value;
        end
    end

    methods (Access = private) % types.untyped.Set callback functions
        function onSetItemAdded(obj, name, groupName)
        % onSetItemAdded - Handle items being added to a contained types.untyped.Set
            obj.createDynamicProperty(name, groupName)
        end

        function onSetItemRemoved(obj, name, groupName)
        % onSetItemRemoved - Handle items being removed from a contained types.untyped.Set
            obj.deleteDynamicProperty(name, groupName)
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
