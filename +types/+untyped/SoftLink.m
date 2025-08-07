classdef SoftLink < handle
    
    properties (SetAccess = private)
        target = [];
    end
    
    properties (Hidden, SetAccess = private)
        path = '';
    end
    
    methods
        function obj = SoftLink(target)
        % SOFTLINK - Create a SoftLink utility object.
        %
        % obj = types.untyped.SOFTLINK(target) creates a SoftLink using an 
        % existing NWB object as a target.
            
            if ischar(target) || isstring(target)
                validateattributes(target, {'char', 'string'}, {'scalartext'}, ...
                    'types.untyped.SoftLink', 'target string', 1);
                obj.path = char(target);
                warning('NWB:SoftLink:DeprecatedPath', ...
                    ['Creating a SoftLink using a string path is deprecated.\n' ...
                     'Please provide a valid NWB object as the target instead.']);
            else
                validateattributes(target, {'types.untyped.MetaClass'}, {'scalar'}, ...
                    'types.untyped.SoftLink', 'target object', 2);
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
            obj.target = refobj;
            if ~nargout
                clear refobj
            end
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

    methods (Static)
        function warningResetObj = disablePathDeprecationWarning()
            warnState = warning('off', 'NWB:SoftLink:DeprecatedPath');
            warningResetObj = onCleanup(@() warning(warnState));
        end
    end
end