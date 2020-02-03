classdef Dataset < h5.interface.IsObject...
        & h5.interface.IsHdfData...
        & h5.interface.HasAttributes
    %DATASET HDF5 Dataset for regular datatypes
    
    methods (Static)
        function Dataset = create(Parent, name, varargin)
            MSG_ID_CONTEXT = 'NWB:H5:Dataset:Create:';
            assert(isa(Parent, 'h5.interface.HasId'),...
                [MSG_ID_CONTEXT 'InvalidArgument'], 'Parent must have an ID');
            
            p = inputParser;
            p.addParameter('space', h5.Space.create(h5.const.SpaceType.Null),...
                @(s)assert(isa(s, 'h5.Space'),...
                [MSG_ID_CONTEXT 'InvalidKeywordArgument'],...
                '`space` must be a `h5.Space`'));
            p.addParameter('type', h5.Type(h5.const.PrimitiveTypes.U8.constant),...
                @(t)assert(isa(t, 'h5.Type'),...
                [MSG_ID_CONTEXT 'InvalidKeywordArgument'],...
                '`type` must be a `h5.Type`'));
            p.addParameter('dcpl', h5.DatasetCreationPropertyList.create(),...
                @(d)assert(isa(d, 'h5.DatasetCreationPropertyList'),...
                [MSG_ID_CONTEXT 'InvalidKeywordArgument'],...
                '`dcpl` must be a valid h5.DatasetCreationPropertyList'));
            p.parse(varargin{:});
            Space = p.Results.space;
            Type = p.Results.type;
            Dcpl = p.Results.dcpl;
            
            lcpl = 'H5P_DEFAULT';
            dapl = 'H5P_DEFAULT';
            did = H5D.create(Parent.get_id(), name,...
                Type.get_id(), Space.get_id(), lcpl, Dcpl.get_id(), dapl);
            if Type.typeClass == h5.const.TypeClass.Compound
                Dataset = h5.CompoundDataset(name, did);
            else
                Dataset = h5.Dataset(did);
            end
        end
        
        function Dataset = open(Parent, name)
            assert(isa(Parent, 'h5.interface.HasId'),...
                'NWB:H5:Dataset:InvalidArgument', 'Parent must have an ID');
            did = H5D.open(Parent.get_id(), name);
            Dataset = h5.Dataset(did);
        end
    end
    
    properties (SetAccess = private, Dependent)
        name;
    end
    
    properties (Access = private)
        id;
    end
    
    properties (Access = private, Dependent)
        dcpl;
    end
    
    properties (SetAccess = private, Dependent)
        chunkSize;
        deflateLevel;
    end
    
    methods % lifecycle
        function obj = Dataset(id)
            obj.id = id;
        end
        
        function delete(obj)
            H5D.close(obj.id);
        end
    end
    
    methods % set/get
        function Dcpl = get.dcpl(obj)
            Dcpl = h5.DatasetCreationPropertyList(H5D.get_create_plist(obj.id));
        end
        
        function size = get.chunkSize(obj)
            size = obj.dcpl.chunkSize;
        end
        
        function level = get.deflateLevel(obj)
            level = obj.dcpl.deflateLevel;
        end
        
        function name = get.name(obj)
            name = obj.get_name();
        end
    end
    
    methods % HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
    
    methods (Access = protected) % HasSpace
        function id = get_space_id(obj)
            id = H5D.get_space(obj.id);
        end
    end
    
    methods (Access = protected) % HasType
        function id = get_type_id(obj)
            id = H5D.get_type(obj.id);
        end
    end
    
    methods % IsHdfData
        function write(obj, data, varargin)
            MSG_ID_CONTEXT = 'NWB:H5:Dataset:Write:';
            
            p = inputParser;
            p.addParameter('type', h5.Type.empty,...
                @(t)assert(isa(t, 'h5.Type'),...
                [MSG_ID_CONTEXT 'InvalidKeywordArgument'],...
                '`type` must be a h5.Type'));
            p.addParameter('space', h5.Space.empty,...
                @(s)assert(isa(s, 'h5.Space'),...
                [MSG_ID_CONTEXT 'InvalidKeywordArgument'],...
                '`space` must be a h5.Space'));
            p.addParameter('selection', h5.space.Hyperslab.empty,...
                @(sel)assert(isa(sel, 'h5.space.Hyperslab'),...
                [MSG_ID_CONTEXT 'InvalidKeywordArgument'],...
                '`selection` must be a h5.space.Hyperslab'));
            p.parse(varargin{:});
            
            MemType = p.Results.type;
            MemSpace = p.Results.space;
            Selection = p.Results.selection;
            
            if isempty(MemType)
                tid = 'H5ML_DEFAULT';
            else
                tid = MemType.get_id();
            end
            
            if isempty(MemSpace)
                memsid = h5.const.Space.AllSpace.constant;
            else
                memsid = MemSpace.get_id();
            end
            
            if isempty(Selection)
                sid = h5.const.Space.AllSpace.constant;
            else
                DataSpace = obj.get_space();
                for i = 1:length(Selection)
                    Slab = Selection(i);
                    
                    newExtents = max([DataSpace.extents; Slab.bounds], 1);
                    DataSpace.extents = newExtents;
                    
                    newDims = max([DataSpace.dims; Slab.bounds], 1);
                    DataSpace.dims = newDims;
                end
                
                DataSpace.select(Selection);
                sid = DataSpace.get_id();
            end
            
            pid = 'H5P_DEFAULT';
            H5D.write(obj.id,...
                tid,...
                memsid,...
                sid,...
                pid,...
                obj.serialize_data(data));
        end
        
        function data = read(obj, varargin)
            p = inputParser;
            p.addParameter('selection', h5.space.Hyperslab.empty,...
                @(s)assert(isa(s, 'h5.space.Hyperslab'),...
                'NWB:H5:Dataset:Read:InvalidKeywordArgument',...
                '`selection` must be a h5.space.Hyperslab.'));
            p.parse(varargin{:});
            Selection = p.Results.selection;
            
            DataSpace = obj.get_space();
            if isempty(Selection)
                sid = h5.const.Space.AllSpace.constant;
            else
                ReadSpace = h5.space.SimpleSpace.from_hyperslabs(Selection);
                DataSpace.select(Selection);
                sid = ReadSpace.get_id();
            end
            
            dxpl = 'H5P_DEFAULT';
            data = H5D.read(obj.id,...
                'H5ML_DEFAULT',...
                sid,...
                DataSpace.get_id(),...
                dxpl);
        end
    end
end