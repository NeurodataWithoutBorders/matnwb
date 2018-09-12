classdef Set < handle & matlab.mixin.CustomDisplay
    properties(SetAccess=protected)
        map; %containers.Map
        fcn; %validation function
    end
    
    methods
        function obj = Set(map, fcn)
            if nargin >= 2
                obj.fcn = fcn;
            else
                obj.fcn = [];
            end
            %clone the map
            obj.map = containers.Map;
            if nargin >= 1
                mapkeys = keys(map);
                for i=1:length(mapkeys)
                    mk = mapkeys{i};
                    obj.set(mk, map(mk));
                end
            end
        end
        
        %return object's keys
        function k = keys(obj)
            k = keys(obj.map);
        end
        
        %return values of backed map
        function v = values(obj)
            v = values(obj.map);
        end
        
        %return number of entries
        function cnt = Count(obj)
            cnt = obj.map.Count;
        end
        
        function setValidationFcn(obj, fcn)
            if (~isnumeric(fcn) || ~isempty(fcn)) && ~isa(fcn, 'function_handle')
                error('Validation must be a function handle of form @(name, val) or empty array.');
            end
            obj.fcn = fcn;
        end
        
        function validateAll(obj)
            mapkeys = keys(obj.map);
            for i=1:length(mapkeys)
                mk = mapkeys{i};
                obj.fcn(mk, obj.map(mk));
            end
        end
        
        function obj = set(obj, name, val)
            if ischar(name)
                name = {name};
            end
            cellExtract = iscell(val);
            assert(length(name) == length(val),...
                'number of property names should match number of vals on set.');
            if ~isempty(obj.fcn)
                for i=1:length(name)
                    if cellExtract
                        elem = val{i};
                    else
                        elem = val(i);
                    end
                    obj.fcn(name{i}, elem);
                end
            end
            for i=1:length(name)
                if cellExtract
                    elem = val{i};
                else
                    elem = val(i);
                end
                obj.map(name{i}) = elem;
            end
        end
        
        function obj = delete(obj, name)
            obj.map(name) = [];
        end
        
        function obj = clear(obj)
            obj.map = containers.Map;
        end
        
        function o = get(obj, name)
            if ischar(name)
                name = {name};
            end
            o = cell(length(name),1);
            for i=1:length(name)
                o{i} = obj.map(name{i});
            end
            if isscalar(o)
                o = o{1};
            end
        end
        
        function refs = export(obj, fid, fullpath, refs)
            io.writeGroup(fid, fullpath);
            k = keys(obj.map);
            val = values(obj.map, k);
            for i=1:length(k)
                v = val{i};
                nm = k{i};
                propfp = [fullpath '/' nm];
                if startsWith(class(v), 'types.')
                    refs = v.export(fid, propfp, refs); 
                else
                    refs = io.writeDataset(fid, propfp, class(v), v, refs);
                end
            end
        end
    end
    
    methods(Access=protected)
        function displayScalarObject(obj)
            hdr = getHeader(obj);
            footer = getFooter(obj);
            mkeys = keys(obj);
            mklen = 0;
            for i=1:length(mkeys)
                mk = mkeys{i};
                if length(mk) > mklen
                    mklen = length(mk);
                end
            end
            body = cell(size(mkeys));
            for i=1:length(mkeys)
                mk = mkeys{i};
                mkspace = repmat(' ', 1, mklen - length(mk));
                body{i} = [mkspace mk ': [' class(obj.map(mk)) ']'];
            end
            body = file.addSpaces(strjoin(body, newline), 4);
            disp([hdr newline body newline footer]);
        end
    end
    
    methods(Access=private)
        %converts to cell string.  Does not do type checking.
        function cellval = merge_stringtypes(obj, val)
            if isstring(val)
                val = convertStringsToChars(val);
            end
            
            if ischar(val)
                cellval = {val};
            else
                cellval = val;
            end
        end
    end
end