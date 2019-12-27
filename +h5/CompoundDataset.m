classdef CompoundDataset < h5.Dataset
    %COMPOUNDDATASET in HDF5 represents a product type consisting of
    % multiple primitive types.  This can be represented in MATLAB by an array of
    % structs or a struct of arrays.
    
    methods (Static)
        function Dataset = create(Parent, name, Data, Manifest)
            assert(isa(Parent, 'h5.HasId'),...
                'NWB:H5:CompoundDataset:InvalidArgument', 'Parent must have an ID');
            assert(isa(Parent, 'h5.compound.Manifest'),...
                'NWB:H5:CompoundDataset:InvalidArgument',...
                'a Manifest must be present to create a Compound Dataset');
            
            Data = h5.compound.filter(Data);
            
            columnNames = Manifest.columns;
            numRows = length(Data.(columnNames{1}));
            Space = h5.Space.deriveFromMatlab([numRows 1]);
            did = H5D.create(Parent.get_id(), name,...
                Manifest.to_type().get_id(), Space.get_id(), lcpl_id, dcpl_id, dapl_id);
            Dataset = h5.CompoundDataset(did, name, Manifest);
            Dataset.write(Data);
        end
        
        function Dataset = open(Parent, name)
            assert(isa(Parent, 'h5.HasId'),...
                'NWB:H5:Dataset:InvalidArgument', 'Parent must have an ID');
            did = H5D.open(Parent.get_id(), name);
            Dataset = h5.Dataset(did, name);
        end
    end
    
    properties (SetAccess = private)
        manifest = h5.dataset.compound.Manifest.empty;
    end
    
    methods % lifecycle (override)
        function obj = CompoundDataset(id, name, Manifest)
            obj = obj@h5.Dataset(id, name);
            
            assert(isa(Manifest, 'h5.dataset.compound.Manifest'),...
                'NWB:H5:CompoundDataset:InvalidArgument',...
                ['CompoundDataset requires a Manifest schema to understand what the '...
                'data columns will be.']);
            obj.manifest = Manifest;
        end
    end
    
    methods % IsHdfData (override)
        function write(obj, data)
            Data = h5.compound.filter_data(data);
            
            PLIST_ID = 'H5P_DEFAULT';
            Type = obj.type;
            Space = obj.space;
            H5D.write(obj.id,...
                Type.get_id(), Space.get_id(), Space.get_id(), PLIST_ID, Data);
        end
        
        function data = read(obj)
            data = read@h5.Dataset();
        end
    end
end

