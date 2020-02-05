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
        
        function MissingViews = export(obj, Parent, ~)
            MissingViews = nwb.interface.Reference.empty;
            
            if ~isempty(Parent.get_descendent(obj.name))
                Parent.delete_link(obj.name);
            end
            Parent.add_link(obj.name, obj.path);
        end
    end
    
    methods % IsNamed
        function name = get_name(obj)
            name = obj.name;
        end
    end
end