classdef Attribute < handle
    properties
        name; %attribute key
        doc; %doc string
        required; %bool regarding whether or not this Attribute is required for class
        value; %Value
        readonly; %determines whether value can be changed or not
        dtype; %type of value
        dependent; %set externally.  If the attribute is actually dependent on an untyped dataset/group
        scalar; %if the value is scalar or an array
        dimnames;
        shape;
    end
    
    methods
        function obj = Attribute(source)
            %defaults
            obj.name = '';
            obj.doc = '';
            obj.required = false;
            obj.value = [];
            obj.readonly = false;
            obj.dtype = '';
            obj.dependent = '';
            obj.scalar = false;
            obj.shape = {};
            obj.dimnames = {};
            
            if nargin < 1
                return;
            end
            
            %source is a java.util.HashMap
            obj.name = source.get('name');
            obj.doc = source.get('doc');
            req = source.get('required');
            if ~isempty(req)
                obj.required = ~strcmp(req, 'false');
            end
            
            val = source.get('value');
            default = source.get('default_value');
            if isempty(default)
                %constant attribute
                obj.value = val;
                obj.readonly = true;
            else
                %changeable attribute
                obj.value = default;
                obj.readonly = false;
            end
            
            dims = source.get('dims');
            shape = source.get('shape');
            if isempty(dims)
                obj.shape = {1};
                obj.dimnames = {{obj.name}};
            else
                [obj.shape, obj.dimnames] = file.procdims(dims, shape);
            end
            
            obj.dtype = file.mapType(source.get('dtype'));
        end
    end
end