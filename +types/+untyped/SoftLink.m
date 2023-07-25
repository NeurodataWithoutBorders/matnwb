classdef SoftLink < handle
    
    properties (Hidden, SetAccess = private)
        target = [];
    end
    
    properties (SetAccess = private)
        path = '';
    end
    
    methods
        function obj = SoftLink(target)
            %SOFTLINK HDF5 soft link.
            % obj = SOFTLINK(path) make soft link given a HDF5 full path.
            % path = HDF5-friendly path e.g. '/acquisition/es1'
            % obj = SOFTLINK(target) make soft link from pre-existant
            % object.
            % target = pre-generated NWB object.
            
            if ischar(target) || isstring(target)
                validateattributes(target, {'char', 'string'}, {'scalartext'} ...
                    , 'types.untyped.SoftLink', 'target string', 1);
                obj.path = char(target);
            else
                validateattributes(target, {'types.untyped.MetaClass'}, {'scalar'} ...
                    , 'types.untyped.SoftLink', 'target object', 2);
                obj.target = target;
            end
        end
        
        function set.path(obj, val)
            validateattributes(val, {'char', 'string'}, {'scalartext'} ...
                , '(types.untyped.SoftLink).path', 'path', 2);
            obj.path = val;
        end
        
        function p = get.path(obj)
            if isempty(obj.path)
                if isempty(obj.target)
                    p = '';
                else
                    p = obj.target.metaClass_fullPath;
                end
            else
                p = obj.path;
            end
        end
        
        function refobj = deref(obj, nwb)
            assert(isa(nwb, 'NwbFile'),...
                'NWB:SoftLink:Deref:InvalidArgument',...
                'Argument `nwb` must be a valid `NwbFile`');
            
            refobj = nwb.resolve({obj.path});
        end
        
        function refs = export(obj, fid, fullpath, refs)
            if isempty(obj.path)
                refs{end+1} = fullpath;
                return;
            end
            
            if isempty(obj.path)
                target_path = obj.target.metaClass_fullPath;
            else
                target_path = obj.path;
            end
            
            plist = 'H5P_DEFAULT';
            try
                H5L.create_soft(target_path, fid, fullpath, plist, plist);
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
end