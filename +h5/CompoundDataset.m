classdef CompoundDataset < h5.Dataset
    %COMPOUNDDATASET in HDF5 represents a product type consisting of
    % multiple primitive types.  This can be represented in MATLAB by an array of
    % structs or a struct of arrays.
    
    methods (Static)
        function Dataset = open(Parent, name)
            assert(isa(Parent, 'h5.HasId'),...
                'NWB:H5:Dataset:InvalidArgument', 'Parent must have an ID');
            did = H5D.open(Parent.get_id(), name);
            Type = h5.Type(H5D.get_type(did));
            assert(Type.get_class() == h5.const.TypeClass.Compound,...
                'NWB:H5:Dataset:InvalidDataType',...
                'A Compound Dataset is Required');
            Dataset = h5.CompoundDataset(did, name);
        end
    end
    
    properties (SetAccess = private)
        manifest = h5.dataset.compound.Manifest.empty;
    end
    
    methods % lifecycle (override)
        function obj = CompoundDataset(name, id)
            obj = obj@h5.Dataset(name, id);
            obj.manifest = h5.compound.Manifest.from_type(obj.get_type());
        end
    end
end

