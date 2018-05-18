classdef ObjectView
    properties(SetAccess=private)
        path;
    end
    
    methods
        function obj = ObjectView(path)
            obj.path = path;
        end
        
        function v = refresh(obj, nwb)
            if ~isa(nwb, 'nwbfile')
                error('Argument `nwb` must be a valid `nwbfile`');
            end
            v = nwb.resolve(obj.path);
        end
        
        function refs = export(obj, ~, ~, path, refs)
            refs(path) = struct('loc', obj.path, 'range', []);
        end
    end
end