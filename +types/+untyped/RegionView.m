classdef RegionView
    properties(SetAccess=private)
        view;
        range;
    end
    
    methods
        function obj = RegionView(nwb, path, range)
            obj.view = types.untyped.ObjectView(nwb, path);
            obj.range = range;
            obj.refresh();
        end
        
        function v = refresh(obj)
            obj.view.refresh();
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