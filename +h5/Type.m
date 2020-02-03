classdef Type < h5.interface.HasId
    %TYPE H5 Type.  Enumeration over predefined data types.
    
    methods (Static)
        function Type = from_manifest(Manifest)
            Type = h5.Type(H5T.create('H5T_COMPOUND', Manifest.get_total_size()));
            
            for i = 1:length(Manifest.columns)
                offset = Manifest.get_offset(Manifest.columns{i});
                SubType = Manifest.mapping.(Manifest.columns{i});
                H5T.insert(Type.get_id(), Manifest.columns{i}, offset, SubType.get_id());
            end
            
            H5T.pack(Type.get_id());
        end
        
        function Type = from_matlab(MatlabType)
            % we limit ourselves to the predefined native types and standard datatypes when applicable
            % https://portal.hdfgroup.org/display/HDF5/Predefined+Datatypes
            % for compound types see h5.compound.CompoundType
            
            switch MatlabType
                case 'types.untyped.ObjectView'
                    tid = h5.PrimitiveTypes.ObjectRef;
                case 'types.untyped.RegionView'
                    tid = h5.PrimitiveTypes.DatasetRegionRef;
                case {matlab.PrimitiveTypes.char,...
                        matlab.PrimitiveTypes.cell,...
                        matlab.PrimitiveTypes.datetime}
                    tid = H5T.copy(h5.PrimitiveTypes.CString);
                    H5T.set_size(tid, 'H5T_VARIABLE'); % variable-length type.
                otherwise
                    tid = h5.PrimitiveTypes.from_matlab(MatlabType);
            end
            
            Type = h5.Type(tid);
        end
    end
    
    properties (Access = private)
        id;
    end
    
    properties (SetAccess = private, Dependent)
        class;
    end
    
    methods % lifecycle
        function obj = Type(id)
            obj.id = id;
        end
        
        function delete(obj)
            if isa(obj.id, 'H5ML.id')
                H5T.close(obj.id);
            end
        end
    end
    
    methods % set/get
        function TypeClass = get.class(obj)
            TypeClass = H5T.get_class(obj.id);
        end
    end
    
    methods % h5.HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
end

