classdef Compression < types.untyped.datapipe.Filter
    %COMPRESSION Deflate compression filter
    
    properties
        level = 3;
    end
    
    methods
        function obj = Compression(level)
            obj.level = level;
        end
    end
    
    methods % Filter
        function addTo(obj, dcpl)
            H5P.set_deflate(dcpl, obj.level);
        end
        
        function name = getName(~)
            name = 'compression';
        end
    end
end

