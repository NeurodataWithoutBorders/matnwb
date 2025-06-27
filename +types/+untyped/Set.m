classdef Set < dynamicprops & matlab.mixin.CustomDisplay
% Set - A (utility) container class for storing neurodata types.
%
%   Neurodata types are added to the Set with name keys, forming name-value 
%   pairs referred to as entries.  

    properties (Access = private)
        DynamicPropertiesMap % containers.Map (name) -> (meta.DynamicProperty)
        DynamicPropertyToH5Name (:,2) cell % cell string matrix where first column is (name) and second column is (hdf5 name)
        
        ValidationFunction function_handle = function_handle.empty() % validation function
        PropertyManager matnwb.utility.DynamicPropertyManager
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

            obj.PropertyManager = matnwb.utility.DynamicPropertyManager(obj);

            if nargin == 0
                return;
            end

            % Handles case where `fcn` is passed as last input
            varargin = obj.popValidationFunctionFromArgsIfPresent(varargin);

            obj.addDynamicPropertiesFromArgsIfPresent(varargin)
        end

        %% validation function propagation
        function set.ValidationFunction(obj, value)
            obj.ValidationFunction = value;

            if ~isempty(obj.ValidationFunction)
                obj.validateAll("mode", "warn")
            end
        end
        
        function validateEntry(obj, name, value)
            if ~isempty(obj.ValidationFunction)
                try
                    obj.ValidationFunction(name, value);
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

            allPropertyNames = obj.PropertyManager.getPropertyNames();
            for iPropName = 1:length(allPropertyNames)
                propertyName = allPropertyNames{iPropName};
                propertyValue = obj.(propertyName);
                
                originalName = obj.PropertyManager.getOriginalName(propertyName);
                propertyFullPath = [fullpath '/' originalName];
                
                if startsWith(class(propertyValue), 'types.')
                    refs = propertyValue.export(fid, propertyFullPath, refs);
                else
                    io.writeDataset(fid, propertyFullPath, propertyValue);
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
        % horzcat - overloads horzcat(A1,A2,...,An)
            error('NWB:Set:Unsupported',...
                'types.untyped.Set does not support concatenation');
        end

        function C = vertcat(varargin) %#ok<STOUT>
        % vertcat - overloads vertcat(A1, A2,...,An)
            error('NWB:Set:Unsupported',...
                'types.untyped.Set does not support concatenation.');
        end

        function add(obj, name, value)
        % add - Add an element (name, value pair) to the set
            obj.set(name, value, ...
                'FailIfKeyExists', true, ...
                'FailOnInvalidType', true);
        end
    end

    methods (Hidden) % Allows setting custom validation function.
        function setValidationFunction(obj, functionHandle)
            obj.ValidationFunction = functionHandle;
        end
    end
    
    methods (Hidden) % Legacy set/get methods
        function obj = set(obj, names, values, options)
            arguments
                obj types.untyped.Set
                names (1,:) string
                values {mustBeSameLength(values, names)}
                options.FailOnInvalidType (1,1) logical = false
                options.FailIfKeyExists (1,1) logical = false
            end
            
            % Wrap character vector in a cell array to treat it as a single 
            % element. NB: This workaround is also supported by mustBeSameLength
            if ischar(values)
                values = {values};
            end

            for i = 1:length(names)
                if iscell(values)
                    currentValue = values{i}; % Extract from cell array
                else
                    currentValue = values(i); % Extract from regular array
                end

                currentKey = names{i};
                
                keyExists = obj.PropertyManager.existOriginalName(currentKey);

                if options.FailIfKeyExists && keyExists
                    error('NWB:Set:KeyExists', ...
                        'Key `%s` already exists in Set', currentKey)
                end

                try
                    obj.validateEntry(currentKey, currentValue)
                catch ME
                    identifier = 'NWB:Set:FailedValidation';
                    message = 'Failed to add key `%s` to Constrained Set with message:\n  %s';

                    if options.FailOnInvalidType
                        error(identifier, message, currentKey, ME.message)
                    else % Skip while displaying warning
                        warning(identifier, message, currentKey, ME.message);
                        continue
                    end
                end

                if keyExists
                    if isempty(currentValue)
                        obj.remove(currentKey);
                    else
                        propertyName = obj.getPropertyName(currentKey);
                        obj.(propertyName) = currentValue;
                    end
                else
                    obj.addProperty(currentKey, currentValue);
                    if ~isempty(obj.ItemAddedFunction)
                        obj.ItemAddedFunction(currentKey)
                    end
                end
            end
        end

        function values = get(obj, names)

            % NB: This method assumes the names being passed is the actual
            % name, not the MATLAB-valid name.

            if ischar(names)
                names = {names};
            end

            values = cell(length(names),1);
            for i = 1:length(names)
                obj.assertPropertyExists(names{i})
                currentPropertyName = obj.getPropertyName(names{i});
                values{i} = obj.(currentPropertyName);
            end
            if isscalar(values)
                values = values{1};
            end
        end
    end

    % Legacy methods mirroring containers.Map interface
    methods (Hidden)
        function cnt = Count(obj)
            cnt = numel( obj.PropertyManager.getPropertyNames() );
        end

        function keyNames = keys(obj)
            keyNames = obj.PropertyManager.getOriginalNames();
            if iscolumn(keyNames)
                keyNames = transpose(keyNames); % Return as row vector
            end
        end

        function propValues = values(obj)
            allPropNames = keys(obj);
            propValues = cell(size(allPropNames));
            for iProp = 1:length(allPropNames)
                propName = allPropNames{iProp};
                propValues{iProp} = obj.get(propName);
            end
        end

        function remove(obj, nameKeys) % todo
            arguments
                obj types.untyped.Set
                nameKeys (1,:) string
            end

            for iKey = 1:length(nameKeys)
                obj.assertPropertyExists(nameKeys(iKey))
                obj.warnIfDataTypeIsBoundToFile(nameKeys(iKey))
                obj.removeProperty(nameKeys(iKey))
            end
        end
                
        function tf = isKey(obj, name)
            tf = obj.PropertyManager.existOriginalName(name);
            if ~tf && isprop(obj, name)
                warning(['"%s" does not exist as a key of this Set, ', ...
                    'but it exists as the name of the property ', ...
                    'corresponding to the key %s'], name, ...
                    obj.PropertyManager.getOriginalName(name))
            end
        end

        function clear(obj)
            obj.remove( keys(obj) );
        end
    end

    % matlab.mixin.CustomDisplay overrides
    methods (Access = protected)
        function displayEmptyObject(obj)
            hdr = sprintf('  %s with no entries.', ...
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
            hdr = strrep(hdr, 'array with properties:', 'with entries:');
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

    % Methods for adding and removing dynamic properties
    methods (Access = private)
        function assertPropertyExists(obj, nameKey)
            existsProperty = obj.PropertyManager.existOriginalName(nameKey);
            assert(existsProperty, ...
                'NWB:Set:EntryDoesNotExist', ...
                'Set does not contain an entry with name `%s`', nameKey)
        end
        
        function addProperty(obj, name, value)
            arguments
                obj types.untyped.Set
                name (1,1) string
                value
            end
            
            metaProperty = obj.PropertyManager.addProperty(name);
            propertyName = metaProperty.Name;
            
            if ~isempty(obj.ValidationFunction)
                metaProperty.SetMethod = getDynamicSetMethodFilterFunction(propertyName);
            end
            obj.(propertyName) = value;
        end

        function removeProperty(obj, nameKey)
            obj.PropertyManager.removeProperty(nameKey)
            if ~isempty(obj.ItemRemovedFunction)
                % Let potential Set "owner" know that property was removed
                obj.ItemRemovedFunction(nameKey)
            end
        end
    
        function name = getPropertyName(obj, name)
        % getPropertyName - Get property name given the original name for an entry
            
            existsName = obj.PropertyManager.existOriginalName(name);
            assert(existsName, ...
                'NWB:Set:MissingName', ...
                'Could not find property name `%s`', name);

            name = obj.PropertyManager.getPropertyNameFromOriginalName(name);
        end
    
        function warnIfDataTypeIsBoundToFile(obj, nameKey)
            % propertyName = obj.getPropertyName(nameKey);
            % Todo: placeholder for future
        end
    end

    % Constructor argument handling
    methods (Access = private)
        function args = popValidationFunctionFromArgsIfPresent(obj, args)
        % Pop validation function handle from input arguments if present
            if isa(args{end}, 'function_handle')
                obj.ValidationFunction = args{end};
                args(end) = [];
            end
        end
    
        function addDynamicPropertiesFromArgsIfPresent(obj, args)

            if isempty(args)
                return
            end

            [names, values] = extractNamesAndValuesFromArgs(args{:});
            for i = 1:length(names)
                obj.addProperty(names{i}, values{i});
            end
        end
    end
end

function [names, values] = extractNamesAndValuesFromArgs(varargin)
% extractNamesAndValuesFromArgs - Extract names and values from varargin
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

function mustBeSameLength(values, names)
    % Workaround to support character vectors as input for values.
    if ischar(values)
        values = {values};
    end
    
    isValid = length(names) == length(values);
    if ~isValid
        error(...
            'NWB:Set:NameValueLengthMismatch', ...
            ['The number of values must match the number of names ', ...
            'provided to the Set.'])
    end
end
