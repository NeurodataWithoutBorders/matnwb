classdef RegionView < handle
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
        %REGIONVIEW A region reference to a dataset in the same nwb file.
        % obj = REGIONVIEW(path, region)
        % path = char representing the internal path to the dataset.
        % region = cell array whose contents are a 2xn array of bounds where n is
        %   the subscript size
            obj.view = types.untyped.ObjectView(path);
            assert(iscell(region),'RegionView only accepts a cell array of bounds');
            obj.region = region;
        end
        
        %given an sid, this region will return that sid but with the
        %correct selection parameters
        function sid = get_selection(obj, sid)
            H5S.select_none(sid);
            for i=1:length(obj.region)
                reg = obj.region{i};
                H5S.select_hyperslab(sid, 'H5S_SELECT_OR', reg(1,:),...
                    [], [], diff(reg, 1, 1)+1);
            end
        end
        
        function v = refresh(obj, nwb)
            %REFRESH follows references and loads data to memory
            %   DATA = REFRESH(NWB) returns the data defined by the RegionView.
            %   NWB is the nwb object returned by nwbRead.
            
            if isempty(obj.region)
                v = [];
                return;
            end
            
            vobj = obj.view.refresh(nwb);
            
            if isa(vobj.data, 'types.untyped.DataStub')
                sid = obj.get_selection(vobj.data.get_space());
                v = vobj.data.load(sid);
                H5S.close(sid);
            else
                v = vobj.data;
            end
            
            %convert 0-indexed subscript bounds to 1-indexed linear indices.
            dsz = size(v);
            bsizes = zeros(length(obj.region),1);
            boundLIdx = cell(length(obj.region),1);
            for i=1:length(obj.region)
                reg = num2cell(obj.region{i}+1);
                boundLIdx{i} = [sub2ind(dsz,reg{1,:});sub2ind(dsz,reg{2,:})];
                bsizes(i) = diff(boundLIdx{i},1,1) + 1;
            end
            
            lIdx = zeros(sum(bsizes),1);
            for i=1:length(boundLIdx)
                idx = sum(bsizes(1:i-1))+1;
                lIdx(idx:bsizes(i)) = (boundLIdx{i}(1):boundLIdx{i}(2)) .'; 
            end
            
            if istable(v)
                v = v(lIdx, :); %tables only take 2d indexing
            else
                v = v(lIdx);
            end
        end
        
        function refs = export(obj, fid, fullpath, refs)
            io.writeDataset(fid, fullpath, class(obj), obj);
        end
        
        function path = get.path(obj)
            path = obj.view.path;
        end
    end
end