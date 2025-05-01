classdef Set < handle & matlab.mixin.CustomDisplay
    properties(SetAccess=protected)
        Map; % containers.Map
        ValidationFcn = @(key, value)[];
    end

    properties (SetAccess = ?matnwb.mixin.HasUnnamedGroups)
    % These properties enables the HasUnnamedGroups mixin to react when
    % items are added or removed from the Set.
        ItemAddedFunction function_handle
        ItemRemovedFunction function_handle
    end
    
    methods
        function obj = Set(varargin)
            % obj = SET returns an empty set
            % obj = SET(field1,value1,...,fieldN,valueN) returns a set from key value pairs
            % obj = SET(src) can be a struct or map
            % obj = SET(__,fcn) adds a validation function from a handle
            obj.Map = containers.Map;
            
            if nargin == 0
                return;
            end
            
            switch class(varargin{1})
                case 'function_handle'
                    obj.ValidationFcn = varargin{1};
                case {'struct', 'containers.Map'}
                    src = varargin{1};
                    if isstruct(src)
                        srcFields = fieldnames(src);
                        for i=1:length(srcFields)
                            obj.Map(srcFields{i}) = src.(srcFields{i});
                        end
                    else
                        srcKeys = keys(src);
                        obj.set(srcKeys, values(src, srcKeys));
                    end
                    
                    if nargin > 1
                        assert(isa(varargin{2}, 'function_handle'),...
                            '`fcn` Expected a function_handle type');
                        obj.ValidationFcn = varargin{2};
                    end
                case 'char'
                    if mod(length(varargin), 2) == 1
                        assert(isa(varargin{end}, 'function_handle'),...
                            '`fcn` Expected a function_handle type');
                        obj.ValidationFcn = varargin{end};
                        varargin(end) = [];
                    end
                    assert(mod(length(varargin), 2) == 0,...
                        ['KeyWord Argument Count Mismatch.  '...
                        'Number of Keys do not match number of values']);
                    assert(iscellstr(varargin(1:2:end)),...
                        'KeyWord Argument Error: Keys must be char');
                    obj.Map = containers.Map(varargin(1:2:end), varargin(2:2:end));
            end
        end
        
        function tf = isKey(obj, name)
            tf = isKey(obj.Map, name);
        end
        
        %return object's keys
        function k = keys(obj)
            k = keys(obj.Map);
        end
        
        %return values of backed map
        function v = values(obj)
            v = values(obj.Map);
        end
        
        %return number of entries
        function cnt = Count(obj)
            cnt = obj.Map.Count;
        end

        %overloads size(obj)
        function varargout = size(obj, dim)
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
        
        %overloads horzcat(A1,A2,...,An)
        function C = horzcat(varargin)
            error('NWB:Set:Unsupported',...
                'types.untyped.Set does not support concatenation');
        end
        
        %overloads vertcat(A1, A2,...,An)
        function C = vertcat(varargin)
            error('NWB:Set:Unsupported',...
                'types.untyped.Set does not support concatenation.');
        end
        
        function setValidationFcn(obj, fcn)
            assert(isa(fcn, 'function_handle'), ...
                'Validation must be a function handle of form @(name, val) or empty array.');
            obj.ValidationFcn = fcn;
        end
        
        function validateAll(obj)
            mapkeys = keys(obj.Map);
            keyFailed = false(size(mapkeys));
            for i=1:length(mapkeys)
                mk = mapkeys{i};
                try
                    obj.ValidationFcn(mk, obj.Map(mk));
                catch ME
                    warning('NWB:Set:FailedValidation' ...
                        , 'Failed to validate Constrained Set key `%s` with message:\n%s' ...
                        , mk, ME.message);
                    keyFailed(i) = true;
                end
            end
            remove(obj.Map, mapkeys(keyFailed));
        end

        function add(obj, name, val)
        % add - Add an element to the set
            obj.set(name, val, 'FailIfKeyExists', true);
        end
        
        function obj = set(obj, name, val, varargin)
            
            if ischar(name)
                name = {name};
            end
            
            if ischar(val)
                val = {val};
            end

            parser = inputParser();
            addParameter(parser, 'FailOnInvalidType', false);
            addParameter(parser, 'FailIfKeyExists', false);
            parser.parse(varargin{:});

            cellExtract = iscell(val);
            
            assert(length(name) == length(val),...
                'number of property names should match number of vals on set.');
            for i = 1:length(name)
                if cellExtract
                    elem = val{i};
                else
                    elem = val(i);
                end

                if parser.Results.FailIfKeyExists
                    if obj.isKey(name{i})
                        error('NWB:Set:KeyExists', ...
                            'Key `%s` already exists in Set', name{i})
                    end
                end

                try
                    obj.ValidationFcn(name{i}, elem);
                    obj.Map(name{i}) = elem;
                    if ~isempty(obj.ItemAddedFunction)
                        obj.ItemAddedFunction(name{i})
                    end
                catch ME
                    identifier = 'NWB:Set:FailedValidation';
                    message = 'Failed to add key `%s` to Constrained Set with message:\n  %s';

                    if parser.Results.FailOnInvalidType
                        error(identifier, message, name{i}, ME.message)
                    else
                        warning(identifier, message, name{i}, ME.message);
                    end
                end
            end
        end
        
        function obj = remove(obj, name)
            remove(obj.Map, name);
            if ~isempty(obj.ItemRemovedFunction)
                obj.ItemRemovedFunction(name)
            end
        end
        
        function obj = clear(obj)
            obj.Map = containers.Map;
        end
        
        function o = get(obj, name)
            if ischar(name)
                name = {name};
            end
            o = cell(length(name),1);
            for i=1:length(name)
                o{i} = obj.Map(name{i});
            end
            if isscalar(o)
                o = o{1};
            end
        end
        
        function refs = export(obj, fid, fullpath, refs)
            io.writeGroup(fid, fullpath);
            k = keys(obj.Map);
            val = values(obj.Map, k);
            for i=1:length(k)
                v = val{i};
                nm = k{i};
                propFullPath = [fullpath '/' nm];
                if startsWith(class(v), 'types.')
                    refs = v.export(fid, propFullPath, refs);
                else
                    refs = io.writeDataset(fid, propFullPath, v, refs);
                end
            end
        end
    end
    
    methods(Access=protected)
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
            mkeys = keys(obj);
            mklen = cellfun('length', mkeys);
            max_mklen = max(mklen);
            body = cell(size(mkeys));
            for i=1:length(mkeys)
                mk = mkeys{i};
                spacing = repmat(' ', 1, max_mklen - mklen(i));
                body{i} = [spacing mk ': [' class(obj.Map(mk)) ']'];
            end
            body = file.addSpaces(strjoin(body, newline), 4);
            disp([hdr newline body newline footer]);
        end
    end
end