classdef Type < h5.interface.HasId
    %TYPE H5 Type.  Enumeration over predefined data types.
    
    methods (Static)
        function Type = from_primitive(Primitive)
            import h5.const.PrimitiveTypes;
            MSG_ID_CONTEXT = 'NWB:H5:Type:FromPrimitive:';
            assert(isa(Primitive, 'h5.const.PrimitiveTypes'),...
                [MSG_ID_CONTEXT 'InvalidArgument'],...
                'Primitive argument must be a h5.const.PrimitiveTypes');
            
            if Primitive == PrimitiveTypes.CString
                tid = H5T.copy(PrimitiveTypes.CString.constant);
                H5T.set_size(tid, 'H5T_VARIABLE');
            else
                tid = Primitive.constant;
            end
            Type = h5.Type(tid);
        end
        
        function Type = from_manifest(Manifest)
            Type = h5.Type(H5T.create('H5T_COMPOUND', Manifest.get_total_size()));
            
            for i = 1:length(Manifest.columns)
                offset = Manifest.get_offset(Manifest.columns{i});
                SubType = Manifest.mapping.(Manifest.columns{i});
                H5T.insert(Type.get_id(), Manifest.columns{i}, offset, SubType.get_id());
            end
            
            H5T.pack(Type.get_id());
        end
        
        function Type = from_matlab(matlabType)
            import h5.const.PrimitiveTypes;
            % we limit ourselves to the predefined native types and standard datatypes when applicable
            % https://portal.hdfgroup.org/display/HDF5/Predefined+Datatypes
            % for compound types see h5.compound.CompoundType
            
            if any(strcmp(matlabType, {'char', 'datetime'}))
                Primitive = PrimitiveTypes.CString;
            else
                Primitive = PrimitiveTypes.from_matlab(matlabType);
            end
            
            Type = h5.Type.from_primitive(Primitive);
        end
    end
    
    properties (Access = private)
        id;
    end
    
    properties (SetAccess = private, Dependent)
        typeClass;
        byteSize;
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
        function TypeClass = get.typeClass(obj)
            TypeClass = h5.interface.IsConstant.from_constant(...
                'h5.const.TypeClass',...
                H5T.get_class(obj.id));
        end
        
        function size = get.byteSize(obj)
            size = H5T.get_size(obj.id);
        end
    end
    
    methods % h5.HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
end

