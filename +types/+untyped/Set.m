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
    end
    
    methods(Access=protected)
        function out = subsref(obj, s)
            out = {};
            if ischar(s.subs) || iscellstr(s.subs) || isstring(s.subs)
                subs = obj.merge_stringtypes(s.subs);
                
                if length(subs) == 1 && any(strcmp(subs{1}, properties(obj)))
                    out = obj.(subs{1});
                    return;
                end
                for i=1:length(subs)
                    sub = subs{i};
                    if isKey(obj.map, sub)
                        out = [out; obj.map(sub)];
                    end
                end
            end
            
            switch length(out)
                case 1
                    out = out{1};
                case 0
                    out = [];
            end
        end
        
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
                body{i} = [mk mkspace ': [' class(obj.map(mk)) ']'];
            end
            body = file.addSpaces(strjoin(body, newline), 4);
            disp([hdr newline body newline footer]);
        end
    end
    
    methods(Access=private)
        %converts to cell string.  Does not do type checking.
        function cellval = merge_stringtypes(obj, val)
            if issstring(val)
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