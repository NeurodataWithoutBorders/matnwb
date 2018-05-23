classdef RegionView
    properties(SetAccess=private)
        path;
        view;
        range;
        type = 'H5T_STD_REF_DSETREG';
        reftype = 'H5R_DATASET_REGION';
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
                    v = vobj.data.load(obj.range(1), obj.range(2));
                otherwise
                    v = vobj.data(obj.range);
            end
        end
        
        function refs = export(obj, fid, fullpath, refs)
            refs = io.writeDataset(fid, fullpath, class(obj), obj, refs);
        end
        
        function path = get.path(obj)
            path = obj.view.path;
        end
    end
end