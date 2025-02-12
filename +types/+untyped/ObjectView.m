classdef ObjectView < handle
    properties (SetAccess = private, Hidden)
        target = [];
    end
    
    properties (SetAccess = private)
        path = '';
    end
    
    properties (Constant, Hidden)
        type = 'H5T_STD_REF_OBJ';
        reftype = 'H5R_OBJECT';
    end
    
    methods
        function obj = ObjectView(target)
            %OBJECTVIEW a "view" or reference to an object meant to be
            %saved in a different location in the NWB file.
            % obj = ObjectView(path)
            % path = A character or string indicating the full HDF5 path
            % to the target object.
            % obj = ObjectView(target)
            % target = A generated NWB object.
            
            if ischar(target) || isstring(target)
                validateattributes(target, {'char', 'string'}, {'scalartext'} ...
                    , 'types.untyped.ObjectView', 'target string', 1);
                obj.path = char(target);
            else
                validateattributes(target, {'types.untyped.MetaClass'}, {'scalar'} ...
                    , 'types.untyped.ObjectView', 'target object', 1);
                obj.target = target;
            end
        end
        
        function v = refresh(obj, nwb)
            validateattributes(nwb, {'NwbFile'}, {'scalar'});
            
            if isempty(obj.path)
                v = obj.target;
            else
                v = nwb.resolve({obj.path});
            end
        end
        
        function refs = export(obj, fid, fullpath, refs)
            io.writeDataset(fid, fullpath, obj);
        end
        
        function path = get.path(obj)
            if isempty(obj.path)
                if isempty(obj.target)
                    path = '';
                elseif isempty(obj.target.metaClass_fullPath)
                    error('NWB:ObjectView:MissingPath',...
                        ['Target fullpath has not been set yet. '...
                        'Is the referenced object assigned in the NWB File?']);
                else
                    path = obj.target.metaClass_fullPath;
                end
            else
                path = obj.path;
            end
        end

        function tf = has_path(obj)
            if ~isempty(obj.target)
                tf = ~isempty(obj.target.metaClass_fullPath);
            else
                tf = ~isempty(obj.path);
            end
        end
    end
end