classdef SoftLink < handle
    properties
        path;
    end
    
%     properties(Hidden, SetAccess=immutable)
%         type; %type constraint, used by file generation
%     end
    
    methods
        function obj = SoftLink(path)
            obj.path = path;
        end
        
        function set.path(obj, val)
            if ~ischar(val)
                error('Property `path` should be a char array');
            end
            obj.path = val;
        end
        
        function refobj = deref(obj, nwb)
            if ~isa(nwb, 'NwbFile')
                error('Argument `nwb` must be a valid `NwbFile`');
            end
            refobj = io.resolvePath(nwb, obj.path);
        end
        
        function refs = export(obj, fid, fullpath, refs)
            plist = 'H5P_DEFAULT';
            H5L.create_soft(obj.path, fid, fullpath, plist, plist);
        end
    end
end