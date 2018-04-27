classdef RegionView
    properties(SetAccess=private)
        ref;
        range;
    end
    
    methods
        function obj = RegionView(handle, range)
            if ~startsWith(class(handle), 'types.')
                error('DataView can only be instantiated with a generated class.');
            end
            
            handleprops = properties(handle);
            if ~any(strcmp(handleprops, 'data')) && ~any(strcmp(handleprops, 'table'))
                error('Unsupported region reference to type `%s`', class(handle));
            end
            
            obj.ref = handle;
            obj.range = range;
            obj.refresh();
        end
        
        function v = refresh(obj)
            props = properties(obj.ref);
            if any(strcmp(props, 'table'))
                v = obj.ref.table(obj.range, :);
            else
                v = obj.ref.data(obj.range);
            end
        end
    end
end