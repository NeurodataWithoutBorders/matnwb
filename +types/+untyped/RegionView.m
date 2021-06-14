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
        function obj = RegionView(path, varargin)
            %REGIONVIEW A region reference to a dataset in the same nwb file.
            % obj = REGIONVIEW(path, region)
            % path = char representing the internal path to the dataset.
            % region = A cell array of indices
            obj.view = types.untyped.ObjectView(path);
            
            for i = 1:length(varargin)
                dimSel = varargin{i};
                validateattributes(dimSel, {'numeric'}, {'positive', 'vector'});
                assert(length(dimSel) == length(unique(dimSel)),...
                    'NWB:RegionView:DuplicateIndex',...
                    ['Due to how HDF5 handles selections, duplicate indices are not ',...
                    'supported for RegionView. Ensure indices are unique across any given '...
                    'dimension.']);
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
    end
end