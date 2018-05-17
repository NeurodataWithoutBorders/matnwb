classdef DataStub
    properties(SetAccess=private)
        filename;
        path;
    end
    
    methods
        
        function obj = DataStub(filename, path)
            obj.filename = filename;
            obj.path = path;
        end
        
        function data = load(obj, range)
            if nargin > 1 && ~isnumeric(range)
                error('Optional Argument `range` must be numeric');
            end
            data = h5read(obj.filename, obj.path, range(:));
        end
        
        function refs = export(obj, loc_id, name, path, refs)
            data = obj.load();
            refs = io.writeDataset(loc_id, path, name, class(data), refs);
        end
    end
end