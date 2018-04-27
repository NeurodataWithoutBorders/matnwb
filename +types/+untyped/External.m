classdef External
    properties
        filename;
        path;
    end
    
    methods
        function obj = External(filename, path)
            obj.filename = filename;
            obj.path = path;
        end
        
        function data = resolve(obj)
            data = h5read(obj.filename, obj.path);
        end
    end
end