classdef Dataset < handle
    properties(SetAccess=private)
        name;
        doc;
        type;
        dtype;
        isClass;
        isConstrainedSet;
        required;
        scalar;
        shape;
        dimnames;
        attributes;
        linkable;
    end
    
    methods
        function obj = Dataset(source)
            obj.name = '';
            obj.doc = [];
            obj.isClass = false;
            obj.isConstrainedSet = false;
            obj.type = [];
            obj.dtype = [];
            obj.required = true;
            obj.scalar = true;
            
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
                obj.isClass = true;
            elseif ~isempty(parent)
                obj.type = parent;
                obj.isConstrainedSet = true;
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
                    obj.attributes.(nextattr.name) = nextattr;
                end
            end
            
            %linkable if named and has no attributes
            obj.linkable = ~isempty(obj.name) &&...
                (isempty(obj.attributes) || isempty(fieldnames(obj.attributes)));
        end
        
        function [props, varargs] = getProps(obj)
            props = containers.Map;
            varargs = {};
            
            if obj.isConstrainedSet
                varargs = {obj};
            else
                if obj.isClass
                    propname = obj.type;
                else
                    if isempty(obj.name)
                        keyboard;
                    end
                    propname = obj.name;
                end
                props(propname) = obj;
                
                if isstruct(obj.dtype)
                    dtnames = fieldnames(obj.dtype);
                    for i=1:length(dtnames)
                        nm = dtnames{i};
                        props(nm) = obj.dtype.(nm);
                    end
                end
                
                if ~isempty(obj.attributes)
                    attrnames = fieldnames(obj.attributes);
                    for i=1:length(attrnames)
                        nm = attrnames{i};
                        props([propname '_' nm]) = obj.attributes.(nm);
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