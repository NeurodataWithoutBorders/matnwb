classdef Set < dynamicprops & matlab.mixin.CustomDisplay
% Set - A (utility) container class for storing neurodata types.

    properties (Access = private)
        DynamicPropertiesMap % containers.Map (name) -> (meta.DynamicProperty)
        ValidationFunction function_handle = function_handle.empty() % validation function
        DynamicPropertyToH5Name (:,2) cell % cell string matrix where first column is (name) and second column is (hdf5 name)
    end

    properties (Access = ?matnwb.mixin.HasUnnamedGroups)
    % These properties enables the HasUnnamedGroups mixin to react when
    % items are added or removed from the Set.
        ItemAddedFunction function_handle
        ItemRemovedFunction function_handle
    end
    
    methods
        %% Constructor
        function obj = Set(varargin)
            % obj = SET returns an empty set
            % obj = SET(field1,value1,...,fieldN,valueN) returns a set from key value pairs
            % obj = SET(src) can be a struct or map
            % obj = SET(__,fcn) adds a validation function from a handle

            obj.DynamicPropertiesMap = containers.Map(...
                'KeyType', 'char', ...
                'ValueType', 'any');

            if nargin == 0
                return;
            end

            % Pop validation function handle from input arguments
            if isa(varargin{end}, 'function_handle')
                obj.ValidationFunction = varargin{end};
                varargin(end) = [];
            end

            if isempty(varargin)
                return
            end

            [names, values] = extractNamesAndValues(varargin{:});
            for i = 1:length(names)
                obj.addProperty(names{i}, values{i});
            end
        end

        %% validation function propagation
        function set.ValidationFunction(obj, val)
            obj.ValidationFunction = val;

            if ~isempty(obj.ValidationFunction)
                obj.validateAll("mode", "warn")
            end
        end
        
        function validateEntry(obj, name, val)
            if ~isempty(obj.ValidationFunction)
                try
                    obj.ValidationFunction(name, val);
                catch MECause
                    ME = MException('NWB:Set:InvalidEntry', ...
                        'Entry of Constrained Set with key `%s` is invalid.\n', name);
                    ME = ME.addCause(MECause);
                    throw(ME)
                end
            end
        end

        function validateAll(obj, options)
            arguments
                obj types.untyped.Set
                options.Mode (1,1) string ...
                    {mustBeMember(options.Mode, ["warn", "fail"])} = "warn"
            end

            setKeys = obj.keys();
            keyFailed = false(size(setKeys));
            
            for i = 1:length(setKeys)
                currentKey = setKeys{i};
                try
                    obj.validateEntry(currentKey, obj.get(currentKey));
                catch ME
                    keyFailed(i) = true;
                    if options.Mode == "warn"
                        warning('NWB:Set:InvalidEntry', ...
                            'Failed to validate Constrained Set key `%s` with message:\n%s.\nData will be dropped.', ...
                            currentKey, ME.message);
                    else
                        rethrow(ME)
                    end
                end
            end
            obj.remove(setKeys(keyFailed))
        end

        %% Export
        function refs = export(obj, fid, fullpath, refs)
            io.writeGroup(fid, fullpath);

            dynamicPropertyNames = keys(obj.DynamicPropertiesMap);
            for iPropName = 1:length(dynamicPropertyNames)
                propName = dynamicPropertyNames{iPropName};
                h5Name = obj.mapPropertyName2H5Name(propName);
                propValue = obj.(propName);

                propFullPath = [fullpath '/' h5Name];
                if startsWith(class(propValue), 'types.')
                    refs = propValue.export(fid, propFullPath, refs);
                else
                    io.writeDataset(fid, propFullPath, propValue);
                end
            end
        end

        %% size() override

        function varargout = size(obj, dim)
            % overloads size(obj)
            if nargin > 1
                if dim > 1
                    varargout{1} = 1;
                else
                    varargout{1} = obj.Count;
                end
            else
                if nargout == 0 || nargout == 1
                    varargout{1} = [obj.Count, 1];
                else
                    varargout = num2cell( ones(1, nargout) );
                    varargout{1} = obj.Count;
                end
            end
        end

        function C = horzcat(varargin) %#ok<STOUT>
            % overloads horzcat(A1,A2,...,An)
            error('NWB:Set:Unsupported',...
                'types.untyped.Set does not support concatenation');
        end

        function C = vertcat(varargin) %#ok<STOUT>
            % overloads vertcat(A1, A2,...,An)
            error('NWB:Set:Unsupported',...
                'types.untyped.Set does not support concatenation.');
        end

        function add(obj, name, val)
        % add - Add an element to the set
            obj.set(name, val, 'FailIfKeyExists', true);
        end
    end

    methods (Hidden)
        function setValidationFunction(obj, functionHandle)
            obj.ValidationFunction = functionHandle;
        end
    end

    % Methods for adding and removing dynamic properties
    methods (Access = private)
        function addProperty(obj, name, value)
            arguments
                obj types.untyped.Set
                name (1,1) string
                value
            end
            name = char(name);

            validName = matlab.lang.makeValidName(name);
            assert(~obj.isH5Name(name) && ~obj.isPropertyName(validName), ...
                'NWB:Set:DuplicateName', ...
                'The provided property name `%s` (converted to `%s`) is a duplicate name.', ...
                name, validName);
            height = size(obj.DynamicPropertyToH5Name, 1);
            obj.DynamicPropertyToH5Name(height+1, 1:2) = {validName, name};
            obj.DynamicPropertiesMap(validName) = obj.addprop(validName);
            if ~isempty(obj.ValidationFunction)
                DynamicProperty = obj.DynamicPropertiesMap(validName);
                DynamicProperty.SetMethod = getDynamicSetMethodFilterFunction(validName);
            end
            obj.(validName) = value;
        end

        function value = removeProperty(obj, name)
            validateattributes(name, {'char'}, {'scalartext'}, 'removeProperty', 'name', 1);

            assert(obj.isH5Name(name) || obj.isPropertyName(name), ...
                'NWB:Set:MissingName', ...
                'Property name or HDF5 identifier `%s` does not exist for this Set.', ...
                name);

            if obj.isH5Name(name)
                name = obj.mapH5Name2PropertyName(name);
            end
            value = obj.(name);

            delete(obj.DynamicPropertiesMap(name));
            remove(obj.DynamicPropertiesMap, name);
        end
    end

    % Legacy set/get methods
    methods
        function obj = set(obj, name, val, options)
            
            arguments
                obj types.untyped.Set
                name (1,:) string
                val
                options.FailOnInvalidType (1,1) logical = false
                options.FailIfKeyExists (1,1) logical = false
            end
            
            if ischar(val)
                val = {val};
            end

            cellExtract = iscell(val);
            
            assert(length(name) == length(val),...
                'number of property names should match number of vals on set.');
            for i = 1:length(name)
                if cellExtract
                    elem = val{i};
                else
                    elem = val(i);
                end

                propertyAlreadyExists = obj.isKey(name{i});

                if options.FailIfKeyExists && propertyAlreadyExists
                    error('NWB:Set:KeyExists', ...
                        'Key `%s` already exists in Set', name{i})
                end

                try
                    obj.validateEntry(name{i}, elem)
                    
                    propertyName = obj.getValidPropertyName(name{i});

                    if propertyAlreadyExists
                        if isempty(val)
                            obj.remove(propertyName);
                        else
                            obj.(propertyName) = val;
                        end
                    else
                        obj.addProperty(propertyName, elem);
                        if  ~isempty(obj.ItemAddedFunction)
                            obj.ItemAddedFunction(name{i})
                        end
                    end
                catch ME
                    identifier = 'NWB:Set:FailedValidation';
                    message = 'Failed to add key `%s` to Constrained Set with message:\n  %s';

                    if options.FailOnInvalidType
                        error(identifier, message, name{i}, ME.message)
                    else
                        warning(identifier, message, name{i}, ME.message);
                    end
                end
            end
        end

        function o = get(obj, name)
            if ischar(name)
                name = {name};
            end

            o = cell(length(name),1);
            for i=1:length(name)
                currentName = obj.getValidPropertyName(name{i});
                o{i} = obj.(currentName);
            end
            if isscalar(o)
                o = o{1};
            end
        end
    end

    % Legacy methods mirroring containers.Map interface
    methods
        function cnt = Count(obj)
            cnt = obj.DynamicPropertiesMap.Count;
        end

        function keyNames = keys(obj)
            %keyNames = keys(obj.DynamicPropertiesMap);
            keyNames = obj.DynamicPropertyToH5Name(:, 2);
            keyNames = transpose(keyNames);
        end

        function propValues = values(obj)
            propValues = keys(obj);
            for iProp = 1:length(propValues)
                propName = propValues{iProp};
                propValues{iProp} = obj.get(propName);
            end
        end

        function remove(obj, keys)
            if ischar(keys)
                keys = {keys};
            end
            assert(iscellstr(keys), 'NWB:Set:InvalidArgument', ...
                'Keys for elements to remove must be a cell array of strings.');
            for iKey = 1:length(keys)
                obj.removeProperty(keys{iKey});
                obj.removeNameFromNameMap(keys{iKey})
                if ~isempty(obj.ItemRemovedFunction)
                    obj.ItemRemovedFunction(name)
                end
            end
        end
                
        function tf = isKey(obj, name)
            tf = obj.isH5Name(name) || obj.isPropertyName(name);
        end

        function clear(obj)
            obj.remove(keys(obj.DynamicPropertiesMap));
        end
    end

    % matlab.mixin.CustomDisplay overrides
    methods (Access = protected)
        function displayEmptyObject(obj)
            hdr = sprintf('  %s with no elements.', ...
                ['<a href="matlab:helpPopup types.untyped.Set" style="font-weight:bold">'...
                'Set</a>']);
            footer = getFooter(obj);
            disp([hdr newline footer]);
        end

        function displayScalarObject(obj)
            displayNonScalarObject(obj)
        end

        function displayNonScalarObject(obj)
            hdr = getHeader(obj);
            footer = getFooter(obj);
            
            propertyNames = string( properties(obj) );
            paddedPropertyNames = pad(propertyNames, 'left');
        
            numProperties = numel(propertyNames);
            body = cell(1, numProperties);
            for i = 1:numProperties
                propertyName = propertyNames{i};
                propertyType = class(obj.(propertyName));
                body{i} = sprintf('%s: %s', paddedPropertyNames{i}, propertyType);                
            end
            body = file.addSpaces(strjoin(body, newline), 4);
            disp([hdr newline body newline footer]);
        end
    end

    methods (Access = private)
        function name = getValidPropertyName(obj, name)
        % validateName - Validate and convert name to a valid property name
            if obj.isH5Name(name)
                name = obj.mapH5Name2PropertyName(name);
            end
            assert(obj.isPropertyName(name), ...
                'NWB:Set:MissingName', ...
                'Could not find property name `%s`', name);
        end
    end

    % Utility methods for the "valid name" to "h5 name" map
    methods (Access = private)
        function tf = isPropertyName(obj, name)
        % isPropertyName - Check if given name is present in the name map
            arguments
                obj types.untyped.Set
                name (1,1) string
            end
            tf = any(strcmp(obj.DynamicPropertyToH5Name(:,1), name));
        end

        function tf = isH5Name(obj, name)
        % isH5Name - Check if given name is present as h5 name in the name map
            arguments
                obj types.untyped.Set
                name (1,1) string
            end
            tf = any(strcmp(obj.DynamicPropertyToH5Name(:,2), name));
        end

        function propName = mapH5Name2PropertyName(obj, h5Name)
            assert(obj.isH5Name(h5Name));
            rowIndex = find(strcmp(obj.DynamicPropertyToH5Name(:,2), h5Name), 1);
            propName = obj.DynamicPropertyToH5Name{rowIndex,1};
        end

        function h5Name = mapPropertyName2H5Name(obj, propName)
            assert(obj.isPropertyName(propName));
            rowIndex = find(strcmp(obj.DynamicPropertyToH5Name(:,1), propName), 1);
            h5Name = obj.DynamicPropertyToH5Name{rowIndex,2};
        end
    
        function removeNameFromNameMap(obj, name)
            if obj.isH5Name(name)
                name = obj.mapH5Name2PropertyName(name);
            end
            
            rowIndex = find(strcmp(obj.DynamicPropertyToH5Name(:,1), name), 1);
            obj.DynamicPropertyToH5Name(rowIndex, :) = [];
        end
    end
end

function [names, values] = extractNamesAndValues(varargin)
% extractNamesAndValues - Extract names and values from varargin
    if isscalar(varargin)
        assert(isstruct(varargin{1}) || isa(varargin{1}, 'containers.Map'), ...
            'NWB:Set:InvalidArguments', ...
            'Expected a struct or a containers.Map. Got %s', class(varargin{1}));
        
        switch class(varargin{1})
            case 'struct'
                names = fieldnames(varargin{1});
                values = struct2cell(varargin{1});
            case 'containers.Map'
                names = varargin{1}.keys();
                values = varargin{1}.values();
        end
    else
        isValidKeywordArgs = mod(numel(varargin), 2) == 0 ...
            && ( iscellstr(varargin(1:2:end)) || isstring(varargin(1:2:end)) );

        assert( isValidKeywordArgs, ...
            'NWB:Set:InvalidArguments', ...
            'Expected keyword arguments');

        names = varargin(1:2:end);
        values = varargin(2:2:end);
    end
end

function setterFunction = getDynamicSetMethodFilterFunction(name)
% workaround as provided by 
% https://www.mathworks.com/matlabcentral/answers/266684-how-do-i-write-setter-methods-for-properties-with-unknown-names
    setterFunction = @setProp;

    function setProp(obj, val)
        obj.validateEntry(name, val)
        obj.(name) = val;
    end
end
