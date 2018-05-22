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
            if isempty(dims)
                obj.shape = {1};
                obj.dimnames = {{obj.name}};
            else
                [obj.shape, obj.dimnames] = file.Dataset.procdims(dims, shape);
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
    
    methods(Static,Access=private)
        function [sz, names] = procdims(dim, shape)
            %check for optional dims
            if isa(dim, 'java.util.ArrayList')
                dimlen = dim.size();
                names = cell(dimlen,1);
                
                for i=1:dimlen
                    dimopt = dim.get(i-1);
                    if isa(shape, 'java.util.ArrayList')
                        shapeopt = shape.get(i-1);
                    else
                        shapeopt = shape;
                    end
                    
                    [subsz, subnm] = file.Dataset.procdims(dimopt, shapeopt);
                    if iscell(subsz)
                        %nested declaration
                        sz{i} = subsz;
                    else
                        %unnested
                        sz(i) = subsz;
                    end
                    names{i} = subnm;
                end
                if ~iscell(sz)
                    sz = {sz};
                end
            else
                if strcmp(shape, 'null')
                    sz = inf;
                else
                    sz = str2double(shape);
                end
                names = dim;
            end
        end
    end
end