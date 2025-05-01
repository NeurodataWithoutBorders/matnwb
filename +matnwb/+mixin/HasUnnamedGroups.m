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
%   - Event listeners make sure objects of this class are always up-to-date
%     with the included types.untyped.Set objects.
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

    properties (Abstract, Access = protected, Transient)
        GroupPropertyNames % Cell array of property names that contain Sets
    end
    
    properties (Access = private, Transient)
        % DynamicPropertyMap - A containers.Map (name) -> (meta.DynamicProperty)
        % storing the dynamic property objects for each added dynamic
        % property, accessible by the dynamic property name
        DynamicPropertyMap

        % SetItemAddedListener - Listener for ItemAdded events on the Set
        % objects that are stored on the "unnamed group" properties
        SetItemAddedListener event.listener

        % SetItemRemovedListener - Listener for ItemRemoved events on the Set
        % objects that are stored on the "unnamed group" properties
        SetItemRemovedListener event.listener
    end

    methods
        function obj = HasUnnamedGroups()
            obj.DynamicPropertyMap = containers.Map();
        end
    end
    
    methods
        function add(obj, name, value)
            wasSuccess = false;
            
            for i = 1:numel(obj.GroupPropertyNames)
                thisGroupName = obj.GroupPropertyNames{i};
                thisSet = obj.(thisGroupName);
                try
                    thisSet.set(name, value, ...
                        'FailOnInvalidType', true, ...
                        'FailIfKeyExists', true)
                    wasSuccess = true;
                    break
                catch ME
                    if strcmp(ME.identifier, 'NWB:Set:KeyExists')
                        ME = MException('NWB:Set:KeyExists', 'A neurodata object with name `%s` already exists in this `%s`', name, obj.TypeName);
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
                identifier = 'NWB:HasGroupsMixin:AddInvalidType';
                message = 'Object with name `%s` was a "%s", but must be one of the following type(s):\n%s\n';
                allowedTypes = obj.getClassNamesForAllowedGroupTypes();
                allowedTypes = strjoin("  - " + allowedTypes, newline);
                error(identifier, message, name, class(value), allowedTypes)
            end
        end
   
        function remove(obj, name)
            for i = 1:numel(obj.GroupPropertyNames)
                thisGroupName = obj.GroupPropertyNames{i};
                thisSet = obj.(thisGroupName);
                
                if thisSet.isKey(name)
                    try
                        thisSet.remove(name)
                        break
                    catch ME
                        rethrow(ME)
                    end
                end
            end
        end
    end

    methods (Access = protected)
        
        function createListeners(obj)
            for i = 1:length(obj.GroupPropertyNames)
                groupPropName = obj.GroupPropertyNames{i};

                setObj = obj.(groupPropName);

                obj.SetItemAddedListener(i) = addlistener(setObj, ...
                    'ItemAdded', @obj.onSetItemAdded);
                obj.SetItemRemovedListener(i) = addlistener(setObj, ...
                    'ItemRemoved', @obj.onSetItemRemoved);
            end
        end

        function addDynamicProperties(obj)
            % TODO: What if multiple groups have the same subkeys?
            for i = 1:length(obj.GroupPropertyNames)
                groupPropName = obj.GroupPropertyNames{i};
    
                setObj = obj.(groupPropName);
                keys = setObj.keys;

                for j = 1:numel(keys)
                    obj.addSingleDynamicProperty(keys{j}, setObj.get(keys{j}))
                end
            end
        end

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

                    if ~isempty(keys)
                        propList = cell2struct(setObj.values(), keys, 2);
                    else
                        propList = string(missing);
                    end
                    
                    % Create a title for this group
                    title = ['<strong>' groupPropName ' elements:</strong>'];
                    
                    % Add this group to the property groups
                    groups(end+1) = matlab.mixin.util.PropertyGroup(propList, title); %#ok<AGROW>
                end
            end
        end
    end

    methods (Access = private)
        function onSetItemAdded(obj, ~, ~)
            % Todo: can be more specific by receiving event data with names
            % of removed properties
            obj.addDynamicProperties()
        end

        function onSetItemRemoved(obj, ~, ~)
            % Todo: can be more specific by receiving event data with names
            % of removed properties
            obj.pruneDynamicProperties()
        end

        function pruneDynamicProperties(obj)
            dynamicPropertyNames = obj.DynamicPropertyMap.keys();

            subgroupElementNames = string.empty;

            for i = 1:numel(obj.GroupPropertyNames)
                thisGroupName = obj.GroupPropertyNames{i};
                thisSet = obj.(thisGroupName);
            
                subgroupElementNames = [subgroupElementNames, thisSet.keys]; %#ok<AGROW>
            end

            removedPropNames = setdiff(dynamicPropertyNames, subgroupElementNames);
            
            for i = 1:numel(removedPropNames)
                dynamicPropertyMeta = obj.DynamicPropertyMap(removedPropNames{i});
                delete(dynamicPropertyMeta)
                obj.DynamicPropertyMap.remove(removedPropNames{i})
            end
        end
    
        function addSingleDynamicProperty(obj, name, value)
            if ~isprop(obj, name)
                p = obj.addprop(name);
                obj.DynamicPropertyMap(name) = p;
            else
                p = obj.DynamicPropertyMap(name);
                if iscell(p); p = p{1}; end
            end
            p.SetAccess = 'public';
            obj.(name) = value;
            % Dynamic props can only be set from within the class
            p.SetAccess = 'protected';
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
    end
end
