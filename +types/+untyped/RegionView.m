classdef RegionView
    properties(SetAccess=private)
        path;
        view;
        region;
    end
    
    properties(Constant,Hidden)
        type = 'H5T_STD_REF_DSETREG';
        reftype = 'H5R_DATASET_REGION';
    end
    
    methods
        function obj = RegionView(path, region)
            obj.view = types.untyped.ObjectView(path);
            obj.region = region;
        end
        
        %given an sid, this region will return that sid but with the
        %correct selection parameters
        function sid = get_selection(obj, sid)
            H5S.select_none(sid);
            for i=1:length(obj.region)
                coord = obj.region{i} - 1;
                %reshape coord such offset and rank is indexable
                remainder = length(coord) / 2;
                coord = reshape(coord, [2 remainder]);
                blocksz = coord(2, :) - coord(1, :) + 1;
                H5S.select_hyperslab(sid, 'H5S_SELECT_OR', coord(1, :),...
                    [], [], blocksz);
            end
        end
        
        function v = refresh(obj, nwb)
        %REFRESH follows references and loads data to memory
        %   DATA = REFRESH(NWB) returns the data defined by the RegionView.
        %   NWB is the nwb object returned by nwbRead.
            vobj = obj.view.refresh(nwb);
            
            if isa(vobj.data, 'types.untyped.DataStub')
                sid = obj.get_selection(vobj.data.get_space());
                v = vobj.data.load(sid);
                H5S.close(sid);
            else
                v = vobj.data;
            end
            
            indices = [];
            for i=1:length(obj.region)
                coord = obj.region{i};
                indices = [indices coord(1):coord(2)];
            end
            if istable(v)
                v = v(indices, :); %tables only take 2d indexing
            else
                v = v(indices);
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