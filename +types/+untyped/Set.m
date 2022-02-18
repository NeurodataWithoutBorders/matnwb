classdef Set < dynamicprops & matlab.mixin.CustomDisplay
    properties
        internal_validationFunction function_handle = function_handle.empty(); % validation function
    end

    properties (SetAccess = protected)
        internal_dynamicPropertyToH5Name(:,2) cell; % cell string matrix where first column is (name) and second column is (hdf5 name)
    end

    properties (Access = private)
        internal_dynamicPropertiesMap; % containers.Map (name) -> (meta.DynamicProperty)
    end

    methods
        %% Constructor
        function obj = Set(varargin)
            % obj = SET returns an empty set
            % obj = SET(field1,value1,...,fieldN,valueN) returns a set from key value pairs
            % obj = SET(src) can be a struct or map
            % obj = SET(__,fcn) adds a validation function from a handle

            obj.internal_dynamicPropertiesMap = containers.Map(...
                'KeyType', 'char', ...
                'ValueType', 'any');

            if nargin == 0
                return;
            end

            numSourceArguments = length(varargin);
            if isa(varargin{end}, 'function_handle')
                obj.internal_validationFunction = varargin{end};
                numSourceArguments = numSourceArguments - 1;
            end

            if 1 == numSourceArguments
                assert(isstruct(varargin{1}) || isa(varargin{1}, 'containers.Map'), ...
                    'NWB:Untyped:Set:InvalidArguments', ...
                    'Expected a struct or a containers.Map. Got %s', class(varargin{1}));
                if isstruct(varargin{1})
                    sourceMap = containers.Map(fieldnames(varargin{1}), struct2cell(varargin{1}));
                else
                    sourceMap = varargin{1};
                end
            else
                assert(0 == mod(numSourceArguments, 2) ...
                    && iscellstr(varargin(1:2:numSourceArguments)), ...
                    'NWB:Untyped:Set:InvalidArguemnts', ...
                    'Expected keyword arguments');
                sourceMap = containers.Map(...
                    varargin(1:2:numSourceArguments), varargin(2:2:numSourceArguments));
            end

            sourceNames = sourceMap.keys();
            for iKey = 1:length(sourceNames)
                name = sourceNames{iKey};
                obj.addProperty(name, sourceMap(name));
            end
        end

        %% validation function propagation
        function set.internal_validationFunction(obj, val)
            obj.internal_validationFunction = val;

            if ~isempty(obj.internal_validationFunction)
                dynamicPropertyNames = keys(obj.internal_dynamicPropertiesMap);
                for iPropNames = 1:length(dynamicPropertyNames)
                    propName = dynamicPropertyNames{iPropNames};
                    try
                        obj.internal_validationFunction(propName, obj.(propName));
                    catch ME
                        error('NWB:Untyped:Set:ValidationFunctionFailure', ...
                            ['Failed to set validation function with message:\n    ' ...
                            '%s\n\nConsider passing a validation function which passes for all ' ...
                            'current properties or remove `%s` from the Set.'], ...
                            ME.message, ...
                            propName);
                    end
                end
            end
        end

        %% size() override
        %return number of entries
        function cnt = Count(obj)
            cnt = obj.internal_dynamicPropertiesMap.Count;
        end

        function varargout = size(obj, dim)
            % overloads size(obj)
            if nargin > 1
                if dim > 1
                    varargout{1} = 1;
                else
                    varargout{1} = obj.Count;
                end
            else
                if nargout == 1
                    varargout{1} = [obj.Count, 1];
                else
                    [varargout{:}] = ones(nargout,1);
                    varargout{1} = obj.Count;
                end
            end
        end

        function C = horzcat(varargin)
            % overloads horzcat(A1,A2,...,An)
            error('NWB:Set:Unsupported',...
                'types.untyped.Set does not support concatenation');
        end

        function C = vertcat(varargin)
            % overloads vertcat(A1, A2,...,An)
            error('NWB:Set:Unsupported',...
                'types.untyped.Set does not support concatenation.');
        end

        %% Add/Remove Properties
        function addProperty(obj, name, value)
            validateattributes(name, {'char'}, {'scalartext'}, 'addProperty', 'name', 1);

            fixedName = matlab.lang.makeValidName(name, 'Prefix', 'matnwb');
            assert(~obj.isH5Name(name) && ~obj.isPropName(fixedName), ...
                'NWB:Untyped:Set:DuplicateName', ...
                'The provided property name `%s` (converted to `%s`) is a duplicate name.', ...
                name, fixedName);
            height = size(obj.internal_dynamicPropertyToH5Name, 1);
            obj.internal_dynamicPropertyToH5Name(height+1, 1:2) = {fixedName, name};
            obj.internal_dynamicPropertiesMap(fixedName) = obj.addprop(fixedName);
            if ~isempty(obj.internal_validationFunction)
                DynamicProperty = obj.internal_dynamicPropertiesMap(fixedName);
                DynamicProperty.SetMethod = getDynamicSetMethodFilterFunction(fixedName);
            end
            obj.(fixedName) = value;
        end

        function value = removeProperty(obj, name)
            validateattributes(name, {'char'}, {'scalartext'}, 'removeProperty', 'name', 1);

            assert(obj.isH5Name(name) || obj.isPropName(name), ...
                'NWB:Untyped:Set:MissingName', ...
                'Property name or HDF5 identifier `%s` does not exist for this Set.', ...
                name);

            if obj.isH5Name(name)
                name = obj.mapH5Name2PropertyName(name);
            end

            delete(obj.internal_dynamicPropertiesMap(name));
            remove(obj.internal_dynamicPropertiesMap, name);
        end

        %% LEGACY GET/SET METHODS
        function obj = set(obj, name, val)
            validateattributes(name, {'char'}, {'scalartext'}, 'set', 'name', 1);

            if ~obj.isH5Name(name) && ~obj.isPropName(name)
                obj.addProperty(name, val);
                return;
            end

            if obj.isH5Name(name)
                name = obj.mapH5Name2PropertyName(name);
            end

            if isempty(val)
                obj.removeProperty(name);
            else
                obj.(name) = val;
            end
        end

        function o = get(obj, name)
            if obj.isH5Name(name)
                name = obj.mapH5Name2PropertyName(name);
            end
            assert(obj.isPropName(name), 'NWB:Untyped:Set:MissingName', ...
                'Could not find property name `%s`', name);
            o = obj.(name);
        end

        %% LEGACY KEY METHODS
        function propNames = keys(obj)
            propNames = keys(obj.internal_dynamicPropertiesMap);
        end

        function propValues = values(obj)
            propValues = keys(obj);
            for iProp = 1:length(propValues)
                propName = propValues{iProp};
                propValues{iProp} = obj.(propName);
            end
        end

        function remove(obj, keys)
            if ischar(keys)
                keys = {keys};
            end
            assert(iscellstr(keys), 'NWB:Untyped:Set:InvalidArgument', ...
                'removed keys provided must be a cell array of strings.');
            for iKey = 1:length(keys)
                obj.removeProperty(keys{iKey});
            end
        end

        function tf = isKey(obj, name)
            tf = obj.isH5Name(name) || obj.isPropName(name);
        end

        %% Export
        function refs = export(obj, fid, fullpath, refs)
            io.writeGroup(fid, fullpath);

            dynamicPropertyNames = keys(obj.internal_dynamicPropertiesMap);
            for iPropName = 1:length(dynamicPropertyNames)
                propName = dynamicPropertyNames{iPropName};
                h5Name = obj.mapPropName2H5Name(propName);
                propValue = obj.(propName);

                propFullPath = [fullpath '/' h5Name];
                if startsWith(class(propValue), 'types.')
                    refs = propValue.export(fid, propFullPath, refs);
                else
                    io.writeDataset(fid, propFullPath, propValue);
                end
            end
        end
    end

    methods (Access = protected)
        %% matlab.mixin.CustomDisplay overrides

        function displayEmptyObject(obj)
            hdr = ['  Empty '...
                '<a href="matlab:helpPopup types.untyped.Set" style="font-weight:bold">'...
                'Set</a>'];
            footer = getFooter(obj);
            disp([hdr newline footer]);
        end

        function displayScalarObject(obj)
            displayNonScalarObject(obj)
        end

        function displayNonScalarObject(obj)
            hdr = getHeader(obj);
            footer = getFooter(obj);
            mkeys = keys(obj);
            mklen = cellfun('length', mkeys);
            max_mklen = max(mklen);
            body = cell(size(mkeys));
            for i=1:length(mkeys)
                mk = mkeys{i};
                mkspace = repmat(' ', 1, max_mklen - mklen(i));
                body{i} = [mkspace mk ': [' class(obj.(mk)) ']'];
            end
            body = file.addSpaces(strjoin(body, newline), 4);
            disp([hdr newline body newline footer]);
        end
    end

    methods (Access = private)
        %% cell array table utilities
        function tf = isPropName(obj, name)
            validateattributes(name, {'char'}, {'scalartext'}, 'isPropName', 'name', 1);
            tf = any(strcmp(obj.internal_dynamicPropertyToH5Name(:,1), name));
        end

        function tf = isH5Name(obj, name)
            validateattributes(name, {'char'}, {'scalartext'}, 'isH5Name', 'name', 1);
            tf = any(strcmp(obj.internal_dynamicPropertyToH5Name(:,2), name));
        end

        function propName = mapH5Name2PropertyName(obj, h5Name)
            assert(obj.isH5Name(h5Name));
            rowIndex = find(strcmp(obj.internal_dynamicPropertyToH5Name(:,2), h5Name), 1);
            propName = obj.internal_dynamicPropertyToH5Name{rowIndex,1};
        end

        function h5Name = mapPropName2H5Name(obj, propName)
            assert(obj.isPropName(propName));
            rowIndex = find(strcmp(obj.internal_dynamicPropertyToH5Name(:,1), propName), 1);
            h5Name = obj.internal_dynamicPropertyToH5Name{rowIndex,2};
        end


    end
end

function setterFunction = getDynamicSetMethodFilterFunction(name)
% workaround as provided by https://www.mathworks.com/matlabcentral/answers/266684-how-do-i-write-setter-methods-for-properties-with-unknown-names
setterFunction = @setProp;

    function setProp(obj, val)
        if ~isempty(obj.internal_validationFunction)
            obj.internal_validationFunction(name, val);
        end
        obj.(name) = val;
    end
end