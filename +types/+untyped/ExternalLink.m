classdef ExternalLink < handle
    properties(SetAccess=private)
        stub;
    end
    
    methods
        function obj = ExternalLink(filename, path)
            obj.stub = types.untyped.DataStub(filename, path);
        end
        
        function data = deref(obj, nwb)
            data = obj.stub.load(nwb);
        end
        
        function refs = export(obj, ~, loc_id, name, refs)
            plist = 'H5P_DEFAULT';
            H5L.create_external(obj.filename, obj.path, loc_id, name, plist, plist);
        end
    end
end