classdef Link < handle
    
    properties(SetAccess=immutable)
        nwb; %nwbfile into which link should be searching
        filename;
    end
    
    properties
        path;
    end
    
    properties(Hidden, SetAccess=immutable)
        type; %type constraint, used by file generation
    end
    
    methods
        function obj = Link(path, context, type)
            obj.path = path;
            
            %if context is char, then it's an external link
            %if context is nwbfile then it's a softlink
            if ischar(context)
                obj.filename = context;
                obj.nwb = [];
            elseif isa(context, 'nwbfile')
                obj.filename = '';
                obj.nwb = context;
            else
                error('Argument `context` must either be a filename for external links, or a nwbfile for soft links');
            end
            
            if nargin >= 3
                if ~ischar(type)
                    error('Argument `type` must be a char array specifying type');
                end
                obj.type = type;
            end
            obj.deref();
        end
        
        function set.path(obj, val)
            if ~ischar(val)
                error('Property `path` should be a char array');
            end
            obj.path = val;
        end
        
        function refobj = deref(obj)
            if isempty(obj.filename)
                refobj = io.resolvePath(obj.nwb, obj.path);
                if ~isa(refobj, obj.type)
                    error('Expected link to point to a `%s`.  Got `%s`.', obj.type, class(refobj));
                end
            else
                %there are no guarantees regarding external links so just
                %resolve as HDF5 dataset.
                refobj = h5read(obj.filename, obj.path);
            end
        end
        
        function export(obj, loc_id, nm)
            plist = 'H5P_DEFAULT';
            if isempty(obj.filename)
                H5L.create_soft(obj.path, loc_id, nm, plist, plist);
            else
                H5L.create_external(obj.filename, obj.path, loc_id, nm, plist, plist);
            end
        end
    end
end