classdef Type < h5.interface.HasId
    %TYPE H5 Type.  Enumeration over predefined data types.
    
    methods (Static)
        function Type = from_matlab(matlabType)
            import h5.type.H5Types;
            import h5.type.PrimitiveTypes;
            % we limit ourselves to the predefined native types and standard datatypes when applicable
            % https://portal.hdfgroup.org/display/HDF5/Predefined+Datatypes
            % for compound types see h5.compound.CompoundType
            
            switch matlabType
                case 'types.untyped.ObjectView'
                    tid = H5Types.ObjectRef;
                case 'types.untyped.RegionView'
                    tid = H5Types.DatasetRegionRef;
                case {PrimitiveTypes.char, PrimitiveTypes.cell, PrimitiveTypes.datetime}
                    tid = H5T.copy(H5Types.CString);
                    H5T.set_size(tid, 'H5T_VARIABLE'); % variable-length type.
                otherwise
                    tid = H5Types.from_primitive(matlabType);
            end
            
            Type = h5.Type(tid);
        end
    end
    
    properties (Access = private)
        id;
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
    
    methods % h5.HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
end

