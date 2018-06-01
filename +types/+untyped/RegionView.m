classdef RegionView
    properties(SetAccess=private)
        path;
        view;
        region;
        mode; %one of point|block|all|none indicating selection mode
        type = 'H5T_STD_REF_DSETREG';
        reftype = 'H5R_DATASET_REGION';
    end
    
    methods
        function obj = RegionView(path, region, mode)
            obj.view = types.untyped.ObjectView(path);
            obj.region = region;
            obj.mode = mode;
        end
        
        function v = refresh(obj, nwb)
            vobj = obj.view.refresh(nwb);
            switch obj.mode
                case 'point'
                    if istable(vobj.data)
                        indices = false(1, height(vobj.data));
                        for i=1:length(obj.region)
                            coord = obj.region{i};
                            indices(coord(1)) = true;
                        end
                        v = vobj.data(indices, :);
                    else
                        error('types.untyped.RegionView Unsupported Feature!');
                    end
                case 'block'
                    if istable(vobj.data)
                        indices = false(1, height(vobj.data));
                        for i=1:length(obj.region)
                            coord = obj.region{i};
                            indices(coord(1):coord(2)) = true;
                        end
                        v = vobj.data(indices, :);
                    else
                        error('types.untyped.RegionView Unsupported Feature!');
                    end
                case 'all'
                    if isa(vobj.data, 'types.untyped.DataStub')
                        v = vobj.data.load();
                    else
                        v = vobj.data;
                    end
                case 'none'
                    v = [];
                otherwise
                    error('RegionView invalid mode `%s`', obj.mode);
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