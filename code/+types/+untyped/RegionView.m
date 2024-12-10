classdef RegionView < handle
    properties (SetAccess = private)
        path;
        target;
        view;
        region;
    end
    
    properties (Constant, Hidden)
        type = 'H5T_STD_REF_DSETREG';
        reftype = 'H5R_DATASET_REGION';
    end
    
    methods
        function obj = RegionView(target, varargin)
            %REGIONVIEW A region reference to a dataset in the same nwb file.
            % obj = REGIONVIEW(path, region)
            % path = char representing the internal path to the dataset.
            % region = A cell array of indices
            % obj = REGIONVIEW(target, __)
            % target = a generated NWB object.
            
            if isa(target, 'types.untyped.MetaClass')
                validateattributes(target, {'types.untyped.DatasetClass'}, {'scalar'});
            end
            obj.view = types.untyped.ObjectView(target);
            
            for i = 1:length(varargin)
                validateattributes(varargin{i}, {'numeric'}, {'positive', 'vector'});
            end
            obj.region = varargin;
        end
        
        function view = refresh(obj, Nwb)
            %REFRESH follows references and loads data to memory
            %   DATA = REFRESH(NWB) returns the data defined by the RegionView.
            %   NWB is the nwb object returned by nwbRead.
            
            view = cell(size(obj));
            for i = 1:numel(obj)
                view{i} = scalar_refresh(obj(i), Nwb);
            end
            
            if isscalar(view)
                view = view{1};
            end
            
            function v = scalar_refresh(RegionView, Nwb)
                if isempty(RegionView.region)
                    v = [];
                    return;
                end
                
                data = RegionView.view.refresh(Nwb);
                
                if isa(data, 'types.untyped.DataPipe')
                    if isa(data.internal, 'types.untyped.datapipe.BoundPipe')
                        data = data.internal.stub;
                    else
                        data = data.internal.data;
                    end
                elseif isa(data, 'types.untyped.DatasetClass')
                    data = data.data;
                end
                
                v = data(RegionView.region{:});
            end
        end
        
        function refs = export(obj, fid, fullpath, refs)
            io.writeDataset(fid, fullpath, obj);
        end
        
        function path = get.path(obj)
            path = obj.view.path;
        end
        
        function object = get.target(obj)
            object = obj.view.target;
        end
    end
end