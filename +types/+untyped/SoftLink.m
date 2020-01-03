classdef SoftLink < handle
    properties
        name;
        path;
    end
    
    methods
        function obj = SoftLink(name, path)
            obj.name = name;
            obj.path = path;
        end
        
        function set.path(obj, val)
            assert(ischar(val),...
                'NWB:Untyped:SoftLink:SetPath:InvalidArgument',...
                'Property `path` should be a char array');
            obj.path = val;
        end
        
        function refobj = deref(obj, Nwb)
            assert(isa(nwb, 'NwbFile'),...
                'NWB:Untyped:SoftLink:Deref:InvalidArgument',...
                'Argument `nwb` must be a valid `NwbFile`');
            refobj = io.resolvePath(Nwb, obj.path);
        end
        
        function refs = export(obj, fid, fullpath, refs)
            plist = 'H5P_DEFAULT';
            try
                H5L.create_soft(obj.path, fid, fullpath, plist, plist);
            catch ME
                if contains(ME.message, 'name already exists')
                    previousLink = H5L.get_val(fid, fullpath, plist);
                    if ~strcmp(previousLink{1}, obj.path)
                        H5L.delete(fid, fullpath, plist);
                        H5L.create_soft(obj.path, fid, fullpath, plist, plist);
                    end
                else
                    rethrow(ME);
                end
            end
        end
    end
    
    methods % IsNamed
        function name = get_name(obj)
            name = obj.name;
        end
    end
end