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
            if ~isempty(obj.fcn)
                obj.fcn(name, val);
            end
            obj.map(name) = val;
        end
        
        function obj = delete(obj, name)
            obj.map(name) = [];
        end
        
        function obj = clear(obj)
            obj.map = containers.Map;
        end
        
        function o = get(obj, name)
            o = obj.map(name);
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