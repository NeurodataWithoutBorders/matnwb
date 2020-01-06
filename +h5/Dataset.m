classdef Dataset < h5.interface.HasId...
        & h5.interface.IsHdfData...
        & h5.interface.HasAttributes...
        & h5.interface.IsObject
    %DATASET HDF5 Dataset for regular datatypes
    
    methods (Static)
        function Dataset = create(Parent, name, varargin)
            assert(isa(Parent, 'h5.HasId'),...
                'NWB:H5:Dataset:InvalidArgument', 'Parent must have an ID');
            
            p = inputParser;
            p.addParameter('space', h5.Space.create(h5.space.SpaceType.H5S_NULL));
            p.addParameter('type', h5.type.H5Types.H5T_STD_U8LE);
            p.addParameter('dcpl', h5.DatasetCreationPropertyList('H5P_DEFAULT'));
            p.parse(varargin{:});
            Space = p.Results.space;
            Type = p.Results.type;
            Dcpl = p.Results.dcpl;
            
            assert(isa(Type, 'h5.Type'), 'NWB:H5:Dataset:InvalidArgument',...
                '`type` must be a `h5.Type`');
            assert(Type.get_class() ~= h5.const.TypeClass.Compound,...
                'NWB:H5:Dataset:CompoundTypeDatasets
            if Type.get_class() == h5.const.TypeClass.Compound
                Dataset = h5.CompoundDataset.create();
            end
            
            assert(isa(Space, 'h5.Space'), 'NWB:H5:Dataset:InvalidArgument',...
                '`space` must be a `h5.Space`');
            assert(isa(Dcpl, 'h5.DatasetCreationPropertyList'),...
                'NWB:H5:Dataset:InvalidArgument',...
                '`dcpl` must be a valid h5.DatasetCreationPropertyList');
            
            pid = 'H5P_DEFAULT';
            did = H5D.create(Parent.get_id(), name,...
                Type.get_id(), Space.get_id(), pid, Dcpl.get_id(), pid);
            if Type.get_class() == h5.const.TypeClass.Compound
                Dataset = h5.CompoundDataset(name, did);
            else
                Dataset = h5.Dataset(name, did);
            end
            
        end
        
        function Dataset = open(Parent, name)
            assert(isa(Parent, 'h5.HasId'),...
                'NWB:H5:Dataset:InvalidArgument', 'Parent must have an ID');
            did = H5D.open(Parent.get_id(), name);
            Dataset = h5.Dataset(name, did);
        end
    end
    
    properties (Access = private)
        id;
    end
    
    properties (Access = private, Dependent)
        space;
        dcpl;
    end
    
    properties (SetAccess = private)
        name;
    end
    
    properties (Dependent)
        extents;
    end
    
    properties (SetAccess = private, Dependent)
        dims;
        type;
        chunkSize;
        deflateLevel;
    end
    
    methods % lifecycle
        function obj = Dataset(name, id)
            obj.name = name;
            obj.id = id;
        end
        
        function delete(obj)
            H5D.close(obj.id);
        end
    end
    
    methods % set/get
        function Space = get.space(obj)
            Space = h5.Space(H5D.get_space(obj.id));
        end
        
        function Dcpl = get.dcpl(obj)
            Dcpl = h5.DatasetCreationPropertyList(H5D.get_create_plist(obj.id));
        end
        
        function dims = get.dims(obj)
            dims = obj.space.dims;
        end

        function set.extents(obj, val)
            assert(~isempty(obj.chunkSize),...
                'NWB:H5:Dataset:SetExtents:CannotResize',...
                'Resizing a dataset requires Chunking to be enabled.');
            
            H5D.set_extent(obj.id, fliplr(val));
        end
        
        function extents = get.extents(obj)
            extents = obj.space.extents;
        end
        
        function Type = get.type(obj)
            Type = H5.Type(H5D.get_type(obj.id));
        end
        
        function size = get.chunkSize(obj)
            size = obj.dcpl.chunkSize;
        end
        
        function level = get.deflateLevel(obj)
            level = obj.dcpl.deflateLevel;
        end
    end
    
    methods
        function SelectSpace = make_selection(obj, Hyperslabs)
            %MAKE_SELECTION makes a selection on the *copy* of the dataset's space.
            % used for Region References which require a copied Space.
            
            SelectSpace = obj.space.copy();
            assert(isa(SelectSpace, 'h5.space.SimpleSpace'),...
                'NWB:H5:Dataset:Select:InvalidSpace',...
                ['Space for dataset `%s` is not Simple.  Selection is only possible '...
                'on a simple space.'], obj.name);
            SelectSpace.select(Hyperslabs);
        end
    end
    
    methods % HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
    
    methods % IsNamed
        function name = get_name(obj)
            name = obj.name;
        end
    end
    
    methods % IsHdfData
        function Type = get_type(obj)
            Type = obj.type;
        end
        
        function write(obj, data)
            if isa(obj.type, 'h5.PresetType')
                data = obj.type.filter(data);
                
                if ismember(obj.type,...
                        [h5.PresetType.ObjectReference, h5.PresetType.DatasetRegionReference])
                    assert(~isa(data, 'types.untyped.ObjectView')...
                        && ~isa(data, 'types.untyped.RegionView'),...
                        'NWB:H5:Dataset:PreconversionRequired',...
                        ['Reference data must be converted by this point.  '...
                        'Use h5.File.filter_reference to convert the data.']);
                end
            end
            
            PLIST_ID = 'H5P_DEFAULT';
            H5D.write(obj.id,...
                Type.get_id(), obj.space.get_id(), obj.space.get_id(), PLIST_ID, data);
        end
        
        function data = read(obj, varargin)
            p = inputParser;
            p.addParameter('selection', 'H5S_ALL');
            p.parse(varargin{:});
            Selection = p.Results.Selection;
            if ~ischar(Selection)
                assert(isa(Selection, 'h5.space.SimpleSpace'),...
                    'NWB:H5:Dataset:Read:InvalidSpace',...
                    'Only a Simple space can specify read selections.');
            end
            dxpl = 'H5P_DEFAULT';
            data = H5D.read(obj.id, 'H5ML_DEFAULT', Selection, obj.space, dxpl);
        end
    end
end