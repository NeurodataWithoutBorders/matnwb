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
            switch class(vobj)
                case 'table'
                    v = vobj.data(obj.range, :);
                case 'types.untyped.DataStub'
                    v = vobj.data.load(obj, obj.range(1), obj.range(2));
                otherwise
                    v = vobj.data(obj.range);
            end
        end
        
        function refs = export(obj, ~, ~, path, refs)
            refs(path) = struct('loc', obj.view.path, 'range', obj.range);
        end
    end
end