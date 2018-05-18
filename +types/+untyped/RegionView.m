classdef RegionView
    properties(SetAccess=private)
        view;
        range;
    end
    
    methods
        function obj = RegionView(path, range)
            obj.view = types.untyped.ObjectView(path);
            obj.range = range;
        end
        
        function v = refresh(obj, nwb)
            vobj = obj.view.refresh(nwb);
            props = properties(obj.ref);
            if any(strcmp(props, 'table'))
                v = obj.ref.table(obj.range, :);
            else
                v = obj.ref.data(obj.range);
            end
        end
        
        function refs = export(obj, ~, ~, path, refs)
            refs(path) = struct('loc', obj.view.path, 'range', obj.range);
        end
    end
end