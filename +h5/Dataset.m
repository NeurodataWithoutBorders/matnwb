classdef Dataset < h5.interface.HasId...
        & h5.interface.IsNamed...
        & h5.interface.IsHdfData...
        & h5.interface.HasAttributes
    %DATASET HDF5 Dataset for regular datatypes
    
    methods (Static)
        function Dataset = create(Parent, name, data)
            assert(isa(Parent, 'h5.HasId'),...
                'NWB:H5:Dataset:InvalidArgument', 'Parent must have an ID');
            
            Type = h5.Type.deriveFromMatlab(class(data));
            Space = h5.Space.deriveFromMatlab(Type, size(data));
            did = H5D.create(Parent.get_id(), name,...
                Type.get_id(), Space.get_id(), lcpl_id, dcpl_id, dapl_id);
            Dataset = h5.Dataset(did, name);
            Dataset.write(data);
        end
        
        function Dataset = open(Parent, name)
            assert(isa(Parent, 'h5.HasId'),...
                'NWB:H5:Dataset:InvalidArgument', 'Parent must have an ID');
            did = H5D.open(Parent.get_id(), name);
            Dataset = h5.Dataset(did, name);
        end
    end
    
    properties (Access = private)
        id;
    end
    
    properties (SetAccess = private)
        name;
    end
    
    properties (SetAccess = private, Dependent)
        space;
        type;
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
           Space = H5.Space(H5D.get_space(obj.id)); 
        end
        
        function Type = get.type(obj)
            Type = H5.Type(H5D.get_type(obj.id));
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
        function write(obj, data)
            if isa(obj.type, 'h5.PresetType')
                data = obj.type.filter(data);
                
                if obj.type == h5.PresetType.ObjectReference...
                        || obj.type == h5.PresetType.DatasetRegionReference
                    assert(~isa(data, 'types.untyped.ObjectView')...
                        && ~isa(data, 'types.untyped.RegionView'),...
                        'NWB:H5:Dataset:PreconversionRequired',...
                        ['Reference data must be converted by this point.  '...
                        'Use h5.File.filter_reference to convert the data.']);
                end
            end
            
            PLIST_ID = 'H5P_DEFAULT';
            H5D.write(obj.id,...
                Type.get_id(), obj.space.get_id(), Space.get_id(), PLIST_ID, data);
        end
        
        function data = read(obj)
            data = H5D.read(obj.id);
        end
    end
end