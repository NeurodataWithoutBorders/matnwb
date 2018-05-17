classdef ObjectView
    properties(SetAccess=private)
        ref;
        path;
    end
    
    methods
        function obj = RegionView(nwb, path)
            obj.path = path;
            handle = nwb.resolve(path);
            if ~startsWith(class(handle), 'types.')
                error('DataView can only be instantiated with a generated class.');
            end
            
            handleprops = properties(handle);
            if ~any(strcmp(handleprops, 'data')) && ~any(strcmp(handleprops, 'table'))
                error('Unsupported region reference to type `%s`', class(handle));
            end
            
            obj.ref = handle;
            obj.refresh();
        end
        
        function v = refresh(obj)
            v = obj.ref;
        end
        
        function refs = export(obj, ~, ~, path, refs)
            refs(path) = struct('loc', obj.path, 'range', []);
        end
    end
end