classdef RegionView < nwb.interface.Reference
    methods (Static)
        function Views = from_raw(Parent, refData)
            assert(isa(Parent, 'h5.interface.HasId'),...
                'NWB:Untyped:RegionView:FromRaw:InvalidArgument',...
                'Parent must have a retrievable Id');
            assert(isa(refData, 'uint8'),...
                'NWB:Untyped:RegionView:FromRaw:InvalidArgument',...
                'refData must be raw uint8 data');
            
            Views = types.untyped.RegionView.empty(size(refData, 2), 0);
            for i = 1:size(refData, 2)
                data = refData(:,i);
                did = H5R.dereference(Parent.get_id(),...
                    h5.PrimitiveTypes.DatasetRegionRef.constant,...
                    data);
                Dataset = h5.Dataset(H5I.get_name(did), did);
                Space = h5.space.SimpleSpace(...
                    H5R.get_region(Parent.get_id(),...
                    h5.PrimitiveTypes.DatasetRegionRef.constant,...
                    data));
                Views(i) = types.untyped.RegionView(...
                    Dataset.get_name(),...
                    Space.get_selections());
            end
        end
    end
    
    properties (Dependent, SetAccess = private)
        path;
    end
    
    properties (SetAccess = private)
        view;
        region;
    end
    
    methods
        function obj = RegionView(path, Hyperslabs)
            %REGIONVIEW A region reference to a dataset in the same nwb file.
            % obj = REGIONVIEW(path, region)
            % path = char representing the internal path to the dataset.
            % Hyperslabs = h5.space.Hyperslabs representing a sum of slab selections
            assert(ischar(path),...
                'NWB:Untyped:RegionView:InvalidArgument',...
                'path must be a character array.');
            assert(isa(Hyperslabs, 'h5.space.Hyperslab'),...
                'NWB:Untyped:RegionView:InvalidArgument',...
                '`Hyperslabs` must be an array of `h5.space.Hyperslab` objects');
            
            obj.view = types.untyped.ObjectView(path);
            obj.region = Hyperslabs;
        end
        
        function Space = make_selection(obj, Space)
            assert(isa(Space, 'h5.space.SimpleSpace'),...
                'NWB:Untyped:RegionView:MakeSelection:InvalidArgument',...
                'Only a Simple Space can make Selections.');
            Space.select(obj.region);
        end
        
        function path = get.path(obj)
            path = obj.get_destination();
        end
    end
    
    methods % Reference
        function path = get_destination(obj)
            path = obj.view.path;
        end
        
        function view = refresh(obj, Nwb)
            %REFRESH follows references and loads data to memory
            %   DATA = REFRESH(NWB) returns the data defined by the RegionView.
            %   NWB is the nwb object returned by nwbRead.
            
            if isempty(obj.region)
                view = [];
                return;
            end
            
            ViewObj = obj.view.refresh(Nwb);
            
            if isa(ViewObj.data, 'types.untyped.DataStub')
                Space = ViewObj.data.get_space();
                Space.select(obj.region);
                view = ViewObj.data.load_h5_style(Space);
            else
                view = ViewObj.data;
            end
            
            %convert 0-indexed subscript bounds to 1-indexed linear indices.
            dsz = size(view);
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
            
            if istable(view)
                view = view(lIdx, :); %tables only take 2d indexing
            else
                view = view(lIdx);
            end
        end
        
        function refData = serialize(obj, File)
            ERR_MSG_STUB = 'NWB:Untyped:RegionView:Serialize:';
            assert(isa(File, 'h5.File'), [ERR_MSG_STUB 'InvalidArgument'],...
                '`File` must be a h5.File object.');
            
            rawDataSize = 12;
            
            refDataSize = size(obj);
            refDataSize(1) = refDataSize(1) * rawDataSize;
            refData = zeros(refDataSize, 'uint8');
            
            for i = 1:length(obj)
                start_i = ((i - 1) * rawDataSize) + 1;
                end_i = start_i + rawDataSize - 1;
                refData(start_i:end_i) = File.get_reference_data(obj(i));
            end
        end
    end
end