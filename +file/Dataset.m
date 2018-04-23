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
        isRef;
    end
    
    methods
        function obj = Dataset(source)
            obj.name = '';
            obj.doc = [];
            obj.isConstrainedSet = false;
            obj.type = [];
            obj.dtype = [];
            obj.required = true;
            obj.scalar = true;
            obj.isRef = false;
            
            obj.shape = {};
            obj.dimnames = {};
            obj.attributes = [];
            
            if nargin < 1
                return;
            end
            
            obj.doc = source.get('doc');
            obj.name = source.get('name');
            
            type = source.get('neurodata_type_def');
            parent = source.get('neurodata_type_inc');

            if ~isempty(type)
                obj.type = type;
            elseif ~isempty(parent)
                obj.type = parent;
            end
            
            obj.dtype = file.mapType(source.get('dtype'));
            obj.isRef = isa(obj.dtype, 'java.util.HashMap');
            
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
                obj.attributes = struct();
                attriter = attributes.iterator();
                for i=1:len
                    nextattr = file.Attribute(attriter.next());
                    if isempty(obj.type)
                        nextattr.dependent = obj.name;
                    end
                    obj.attributes.(nextattr.name) = nextattr;
                end
            end
            
            %linkable if named and has no attributes
            obj.linkable = ~isempty(obj.name) &&...
                (isempty(obj.attributes) || isempty(fieldnames(obj.attributes)));
        end
        
        function props = getProps(obj)
            props = containers.Map;
            
            %typed
            % return props as typed props with custom `data`, `ref`, or `table`
            % types
            
            %untyped
            % Return data + all dependent attributes as separate props
            
            %constrained
            % return itself
            
            if obj.isConstrainedSet
                props(lower(obj.type)) = obj;
                return;
            end
            
            if ~isempty(obj.name)
                propname = obj.name;
                props(propname) = obj;
            end
            
            %there are only two classes that do this and they're all under
            %ecephys: ElectrodeTable and ElectrodeTableRegion.
            % one of which is a region reference and the other is a compound
            % type.
            % therefore, we currently do not have a case for a regular typed
            % dataset (because there isn't any.
            if ~isempty(obj.dtype)
                if isstruct(obj.dtype)
                    props('table') = obj.dtype;
                elseif isa(obj.dtype, 'java.util.HashMap')
                    props('ref') = obj.dtype;
                elseif ~isempty(obj.type)
                    %regular dataset
                    props('data') = obj.dtype;
                end
            end
            
            if ~isempty(obj.attributes)
                attrnames = fieldnames(obj.attributes);
                for i=1:length(attrnames)
                    nm = attrnames{i};
                    if isempty(obj.type)
                        props([propname '_' nm]) = obj.attributes.(nm);
                    else
                        props(nm) = obj.attributes.(nm);
                    end
                end
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