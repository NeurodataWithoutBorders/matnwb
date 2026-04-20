classdef Anon < handle
    %anonymous key-value pair as an alternative to single-sized Sets
    properties
        name; %name of object
        value; %mapping value
    end
    
    methods
        function obj = Anon(nm, val)
            obj.name = '';
            obj.value = [];
            
            if nargin > 0
                obj.name = nm;
                obj.value = val;
            end
        end
        
        function set.name(obj, nm)
            assert(ischar(nm),...
                'input `name` should be a non-empty char array');
            obj.name = nm;
        end
        
        function set.value(obj, val)
            obj.value = val;
        end
        
        function tf = isempty(obj)
            tf = isempty(obj.name);
        end
        
        function refs = export(obj, fid, fullpath, refs)
            refs = obj.value.export(fid, [fullpath obj.name '/'], refs);
        end

        function tf = isKey(obj, name)
            tf = strcmp(obj.name, name);
        end
    end

    % Methods mirroring Set methods.
    methods 
        function name = getPropertyName(obj, name)
        % getPropertyName - Get property name given the actual name of an entry
            assert(strcmp(obj.name, name), ...
                'NWB:Anon:InvalidName', ...
                'name `%s` is not part of Anon', name);
        end

        function value = get(obj, name)
            assert(strcmp(obj.name, name), ...
                'NWB:Anon:InvalidName', ...
                'name `%s` is not part of Anon', name);
            value = obj.value;
        end
    end
end
