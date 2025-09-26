classdef Set < dynamicprops & matlab.mixin.CustomDisplay
% Set - A (utility) container class for storing neurodata types.
%
%   Neurodata types are added to the Set with name keys, forming name-value 
%   pairs referred to as entries. 

%   Developer notes:
%   `name` is used throughout this class to refer to the actual name of a Set 
%   entry, not the valid MATLAB identifier used for the Set's dynamic property 
%   names. In legacy methods, `key` is equivalent to `name`.

    properties (Access = private)
        ValidationFunction function_handle = function_handle.empty() % validation function for entries
        PropertyManager matnwb.utility.DynamicPropertyManager
    end

    properties (Access = ?matnwb.mixin.HasUnnamedGroups)
    % These properties enables the HasUnnamedGroups mixin to react when
    % entries are added or removed from the Set.
        EntryAddedFunction function_handle
        EntryRemovedFunction function_handle
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
        
        function value = validateEntry(obj, name, value)
            if ~isempty(obj.ValidationFunction)
                try
                    value = obj.ValidationFunction(name, value);
                catch MECause
                    ME = MException('NWB:Set:InvalidEntry', ...
                        'Entry of Constrained Set with name `%s` is invalid.\n', name);
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

            names = obj.keys();
            isInvalidEntry = false(size(names));
            
            for i = 1:length(names)
                currentName = names{i};
                try
                    obj.validateEntry(currentName, obj.get(currentName));
                catch ME
                    isInvalidEntry(i) = true;
                    if options.Mode == "warn"
                        warning('NWB:Set:InvalidEntry', ...
                            ['Failed to validate entry of Constrained Set with ', ...
                            'name `%s`.\nReason:\n%s.\nData will be dropped.'], ...
                            currentName, ME.message);
                    else
                        rethrow(ME)
                    end
                end
            end
            obj.remove(names(isInvalidEntry))
        end

        %% Export
        function refs = export(obj, fid, fullpath, refs)
            io.writeGroup(fid, fullpath);

            allPropertyNames = obj.PropertyManager.getAllPropertyNames();
            for iPropName = 1:length(allPropertyNames)
                propertyName = allPropertyNames{iPropName};
                propertyValue = obj.(propertyName);
                
                originalName = obj.PropertyManager.getOriginalNameForPropertyName(propertyName);
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
            % add - Add a named data object to the Set
            %
            % Syntax:
            %   add(obj, name, value) adds the specified name-value pair 
            %   to the object's set.
            %
            % Input Arguments:
            %   obj     - The object to which the data object is being added.
            %   name    - The name of the data object to be added.
            %   value   - The data object corresponding to the given name.
            
            obj.set(name, value, ...
                'FailIfKeyExists', true, ...
                'FailOnInvalidType', true);
        end

        function name = getPropertyName(obj, name)
        % getPropertyName - Get property name given the actual name of an entry

            existsName = obj.PropertyManager.existOriginalName(name);
            assert(existsName, ...
                'NWB:Set:MissingName', ...
                'Could not find name `%s` in Set', name);

            name = obj.PropertyManager.getPropertyNameForOriginalName(name);
        end

        function name = getOriginalName(obj, propertyName)
            existsName = obj.PropertyManager.existPropertyName(propertyName);
            assert(existsName, ...
                'NWB:Set:MissingName', ...
                'Could not find property name `%s` in Set', propertyName);

            name = obj.PropertyManager.getOriginalNameForPropertyName(propertyName);
        end
    end

    methods (Hidden) % Allows setting custom validation function.
        function setValidationFunction(obj, functionHandle)
            obj.ValidationFunction = functionHandle;
        end
    
        function T = getPropertyMappingTable(obj)
            T = obj.PropertyManager.getPropertyMappingTable();
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

                currentName = names{i};
                
                existsEntry = obj.PropertyManager.existOriginalName(currentName);

                if options.FailIfKeyExists && existsEntry
                    error('NWB:Set:KeyExists', ...
                        'Entry with name `%s` already exists in Set', currentName)
                end

                try
                    currentValue = obj.validateEntry(currentName, currentValue);
                catch ME
                    identifier = 'NWB:Set:FailedValidation';
                    message = 'Failed to add entry `%s` to Constrained Set with message:\n  %s';

                    if options.FailOnInvalidType
                        error(identifier, message, currentName, ME.message)
                    else % Skip while displaying warning
                        warning(identifier, message, currentName, ME.message);
                        continue
                    end
                end

                if existsEntry
                    if isempty(currentValue)
                        obj.remove(currentName);
                    else
                        propertyName = obj.getPropertyName(currentName);
                        obj.(propertyName) = currentValue;
                    end
                else
                    obj.addProperty(currentName, currentValue);
                    if ~isempty(obj.EntryAddedFunction)
                        obj.EntryAddedFunction(currentName)
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
                obj.assertEntryExists(names{i})
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
            cnt = obj.PropertyManager.getPropertyCount();
        end

        function keySet = keys(obj)
            keySet = obj.PropertyManager.getAllOriginalNames();
            if iscolumn(keySet)
                keySet = transpose(keySet); % Return as row vector
            end
        end

        function valueSet = values(obj)
            keySet = keys(obj);
            valueSet = cell(size(keySet));
            for iKey = 1:length(keySet)
                currentKey = keySet{iKey};
                valueSet{iKey} = obj.get(currentKey);
            end
        end

        function remove(obj, names)
        % remove - Remove a set of entries given their names.
        %
        % Note: The name should be the original (actual) name of the entry,
        % not the property identifier.
        
            arguments
                obj types.untyped.Set
                names (1,:) string
            end

            for iEntry = 1:length(names)
                obj.assertEntryExists(names(iEntry))
                obj.warnIfDataTypeIsBoundToFile(names(iEntry))
                obj.removeProperty(names(iEntry))
            end
        end
                
        function tf = isKey(obj, name)
            tf = obj.PropertyManager.existOriginalName(name);
            if ~tf && isprop(obj, name)
                obj.warnIfPropertyNameExistsButNotOriginalName(name)
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
            hdr = strrep(hdr, 'with properties:', 'with entries:');
            hdr = strrep(hdr, 'array ', '');
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
    
        function str = getFooter(obj)
            T = obj.getPropertyMappingTable();
            if ~isempty(T)
                T(T.ValidIdentifier==T.OriginalName, :) = [];
                types.untyped.internal.displayAliasWarning(T, 'Set')
            end
            str = '';
        end
    end

    % Methods for adding and removing dynamic properties
    methods (Access = private)
        function assertEntryExists(obj, name)
            existsEntry = obj.PropertyManager.existOriginalName(name);
            
            if ~existsEntry && isprop(obj, name)
                obj.warnIfPropertyNameExistsButNotOriginalName(name)
            end

            assert(existsEntry, ...
                'NWB:Set:EntryDoesNotExist', ...
                'Set does not contain an entry with name `%s`', name)
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

        function removeProperty(obj, name)
            obj.PropertyManager.removeProperty(name)
            if ~isempty(obj.EntryRemovedFunction)
                % Let potential Set "owner" know that entry was removed
                obj.EntryRemovedFunction(name)
            end
        end
    
        function warnIfDataTypeIsBoundToFile(obj, name)
            % propertyName = obj.getPropertyName(name);
            % Todo: placeholder for future
        end

        function warnIfPropertyNameExistsButNotOriginalName(obj, name)
            originalName = obj.PropertyManager.getOriginalNameForPropertyName(name);
            warning('NWB:Set:PropertyNameExistsForEntry' ,...
                ['"%s" is not the name for an entry of this Set, ', ...
                'but it exists as the property identifier corresponding ', ...
                'to the entry with name `%s`'], ...
                name, ...
                originalName)
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
        val = obj.validateEntry(name, val);
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
