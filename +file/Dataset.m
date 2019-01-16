classdef Dataset < handle
    properties
        name;
        doc;
        type;
        dtype;
        isConstrainedSet;
        required;
        scalar;
        shape;
        dimnames;
        attributes;
        linkable;
        definesType;
    end
    
    methods
        function obj = Dataset(source)
            obj.name = '';
            obj.doc = '';
            obj.isConstrainedSet = false;
            obj.type = '';
            obj.dtype = '';
            obj.required = true;
            obj.scalar = true;
            obj.definesType = false;
            
            obj.shape = {};
            obj.dimnames = {};
            obj.attributes = [];
            
            if nargin < 1
                return;
            end
            
            obj.doc = char(source.get('doc'));
            obj.name = char(source.get('name'));
            
            type = char(source.get('neurodata_type_def'));
            parent = char(source.get('neurodata_type_inc'));
            
            if isempty(type)
                obj.type = parent;
            else
                obj.type = type;
                obj.definesType = true;
            end
            
            obj.dtype = file.mapType(source.get('dtype'));
            
            quantity = source.get('quantity');
            if ~isempty(quantity)
                switch quantity
                    case '?'
                        obj.required = false;
                        obj.scalar = true;
                    case '*'
                        obj.required = false;
                        obj.scalar = false;
                    case '+'
                        obj.required = true;
                        obj.scalar = false;
                end
            end
            
            obj.isConstrainedSet = ~isempty(obj.type) && ~obj.scalar;
            
            dims = source.get('dims');
            shape = source.get('shape');
            if isempty(shape)
                obj.shape = '1';
                obj.dimnames = {obj.name};
            else
                [obj.shape, obj.dimnames] = file.procdims(shape, dims);
                if iscellstr(obj.shape)
                    obj.scalar = any(strcmp(obj.shape, '1'));
                else
                    obj.scalar = strcmp(obj.shape, '1');
                end
            end
            
            %do attributes
            attributes = source.get('attributes');
            if ~isempty(attributes)
                len = attributes.size();
                obj.attributes = repmat(file.Attribute, len, 1);
                attriter = attributes.iterator();
                for i=1:len
                    nextattr = file.Attribute(attriter.next());
                    if isempty(obj.type)
                        nextattr.dependent = obj.name;
                    end
                    obj.attributes(i) = nextattr;
                end
            end
            
            %linkable if named and has no attributes
            obj.linkable = ~isempty(obj.name) &&...
                (isempty(obj.attributes) || isempty(fieldnames(obj.attributes)));
        end
        
        function props = getProps(obj)
            props = containers.Map;
            
            %typed
            % return props as typed props with custom `data`
            % types
            
            %untyped
            % error, untyped should not hold any data.
            
            %constrained
            % error unless it defines the object.
            
            if isempty(obj.type)
                error('You shouldn''t be calling getProps on an untyped dataset');
            end
            
            if obj.isConstrainedSet && ~obj.definesType
                error('You shouldn''t be calling getProps on a constrained dataset');
            end
            
            if ~isempty(obj.dtype)
                props('data') = obj.dtype;
            end
            
            if ~isempty(obj.attributes)
                props = [props;...
                    containers.Map({obj.attributes.name}, num2cell(obj.attributes))];
            end
        end
    end
end