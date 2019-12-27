classdef HasAttributes < h5.interface.HasId
    %HASATTRIBUTES This HDF5 object can have attributes
    
    methods
        function add_attribute(obj, name, data)
            h5.Attribute.create(obj, name, data);
        end
        
        function remove_attribute(obj, name)
            H5A.delete(obj.get_id(), name);
        end
        
        function Attributes = get_attributes(obj)
            IDX_TYPE = 'H5_INDEX_NAME';
            ITER_ORDER = 'H5_ITER_NATIVE';
            IDX_START = 0;
            [~, ~, attributeNames] = H5A.iterate(...
                obj.get_id(),...
                IDX_TYPE,...
                ITER_ORDER,...
                IDX_START,...
                @eachAttribute,...
                {});
            
            Attributes = h5.Attribute.empty;
            for i = 1:length(attributeNames)
                Attributes(end+1) = h5.Attribute.open(obj, name);
            end
            
            function [status, names] = eachAttribute(~, attr_name, names)
                names{end+1} = attr_name;
                status = 0;
            end
        end
    end
end