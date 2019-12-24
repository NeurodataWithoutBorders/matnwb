classdef Type < h5.HasId
    %TYPE H5 Type.  Enumeration over predefined data types.
    
    methods (Static)
        function Type = deriveType(matlabType)
            % we limit ourselves to the predefined native types and standard datatypes when applicable
            % https://portal.hdfgroup.org/display/HDF5/Predefined+Datatypes
            
            switch matlabType
                case 'types.untyped.ObjectView'
                    Type = h5.DefaultType.ObjectReference;
                case 'types.untyped.RegionView'
                    Type = h5.DefaultType.DatasetRegionReference;
                case {'char', 'cell', 'datetime'}
                    Type = h5.DefaultType.String;
                    Type = h5.Type(H5T.copy(Type.get_id()));
                    H5T.set_size(Type.get_id(), 'H5T_VARIABLE');
                case 'double'
                    Type = h5.DefaultType.Double;
                case 'single'
                    Type = h5.DefaultType.Single;
                case 'logical'
                    Type = h5.DefaultType.Bool;
                case 'int8'
                    Type = h5.DefaultType.I8;
                case 'uint8'
                    Type = h5.DefaultType.U8;
                case 'int16'
                    Type = h5.DefaultType.I16;
                case 'uint16'
                    Type = h5.DefaultType.U16;
                case 'int32'
                    Type = h5.DefaultType.I32;
                case 'uint32'
                    Type = h5.DefaultType.U32;
                case 'int64'
                    Type = h5.DefaultType.I64;
                case 'uint64'
                    Type = h5.DefaultType.U64;
                otherwise
                    error('NWB:H5:Type:InvalidType',...
                        'Type `%s` is not a supported raw type.', matlabType);
            end
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

