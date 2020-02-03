classdef HasAttributes < h5.interface.HasId
    %HASATTRIBUTES This HDF5 object can have attributes
    
    methods
        function add_attribute(obj, name, data)
            h5.Attribute.create(obj, name, data);
        end
        
        function remove_attribute(obj, name)
            H5A.delete(obj.get_id(), name);
        end
        
        function Attributes = get_all_attributes(obj)
            IDX_TYPE = 'H5_INDEX_NAME';
            ITER_ORDER = 'H5_ITER_NATIVE';
            IDX_START = 0;
            [~, ~, Attributes] = H5A.iterate(...
                obj.get_id(),...
                IDX_TYPE,...
                ITER_ORDER,...
                IDX_START,...
                @eachAttribute,...
                h5.Attribute.empty);
            
            function [status, Attributes] = eachAttribute(parent_id, name, ~, Attributes)
                Attributes(end+1) = h5.Attribute(H5A.open(parent_id, name, 'H5P_DEFAULT'));
                status = 0;
            end
        end
        
        function Attribute = get_attribute(obj, name)
            Attribute = h5.Attribute.open(obj, name);
        end
    end
end