classdef DatasetCreationPropertyList < h5.interface.HasId
    %DATASETCREATIONPROPERTYLIST Represents a H5P list for dataset creation
    
    methods (Static)
        function Dcpl = create()
            Dcpl = h5.DatasetCreationPropertyList(...
                H5P.create('H5P_DATASET_CREATE'));
        end
    end
    
    properties (Access = private)
        id;
    end
    
    properties (Dependent)
        chunkSize;
        deflateLevel;
    end
    
    methods % lifecycle
        function obj = DatasetCreationPropertyList(id)
            obj.id = id;
        end
        
        function delete(obj)
            H5P.close(obj.id);
        end
    end
    
    methods % get/set
        function set.chunkSize(obj, val)
            H5P.set_chunk(obj.id, val);
        end
        
        function size = get.chunkSize(obj)
            try
                [~, h5_chunk_dims] = H5P.get_chunk(obj.id);
                size = fliplr(h5_chunk_dims);
            catch
                size = [];
            end
        end
        
        function set.deflateLevel(obj, val)
            H5P.set_deflate(obj.id, val);
        end
        
        function level = get.deflateLevel(obj)
            numFilters = H5P.get_nfilters(obj.id);
            for i = 0:numFilters-1
                [filter, ~, cd_values, ~, ~] =...
                    H5P.get_filter(obj.id, i);
                
                if filter == H5ML.get_constant_value('H5Z_FILTER_DEFLATE')
                    level = cd_values;
                    return;
                end
            end
            level = -1;
        end
    end
    
    methods % HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
end