classdef Attribute < h5.interface.HasId...
        & h5.interface.IsNamed...
        & h5.interface.IsHdfData
    %ATTRIBUTE HDF5 attribute
    
    methods (Static)
        function Attribute = create(Parent, name, data)
            assert(isa(Parent, 'h5.HasId'),...
                'NWB:H5:Attribute:InvalidArgument', 'Parent must have an ID');
            
            PROPLIST_ID = 'H5P_DEFAULT';
            Type = h5.Type.deriveFromMatlab(class(data));
            Space = h5.Space.deriveFromMatlab(Type, size(data));
            aid = H5A.create(Parent.get_id(), name, Type.get_id(), Space.get_id(),...
                PROPLIST_ID, PROPLIST_ID);
            Attribute = h5.Attribute(aid, name);
            Attribute.write(data);
        end
        
        function Attribute = open(Parent, name)
            assert(isa(Parent, 'h5.HasId'),...
                'NWB:H5:Attribute:InvalidArgument', 'Parent must have an ID');
            
            PROPLIST_ID = 'H5P_DEFAULT';
            Attribute = h5.Attribute(H5A.open_by_name(Parent.get_id(), name,...
                PROPLIST_ID, PROPLIST_ID));
        end
    end
    
    properties (Access = private)
        id;
    end
    
    properties (SetAccess = private)
        name;
    end
    
    methods % lifecycle
        function obj = Attribute(name, id)
            obj.name = name;
            obj.id = id;
        end
        
        function delete(obj)
            H5A.close(obj.id);
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
    
    methods (Access = protected) % HasSpace
        function id = get_space_id(obj)
            id = H5A.get_space(obj.id);
        end
    end
    
    methods (Access = protected) % HasType
        function type_id = get_type_id(obj)
            type_id = H5A.get_type(obj.id);
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
            
            H5A.write(obj.id, obj.type.get_id(), data);
        end
        
        function data = read(obj, varargin)
            data = H5A.read(obj.id, 'H5ML_DEFAULT');
        end
    end
end

