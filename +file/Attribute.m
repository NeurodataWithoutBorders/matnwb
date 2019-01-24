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
            obj.required = true;
            obj.value = [];
            obj.readonly = false;
            obj.dtype = '';
            obj.dependent = '';
            obj.scalar = true;
            obj.shape = {};
            obj.dimnames = {};
            
            if nargin < 1
                return;
            end
            
            %source is a java.util.HashMap
            obj.name = source.get('name');
            obj.doc = source.get('doc');
            req = source.get('required');
            obj.required = isempty(req) || ~strcmp(req, 'false');
            
            val = source.get('value');
            default = source.get('default_value');
            
            if ~isempty(default)
                %changeable attribute
                obj.value = default;
                obj.readonly = false;
            elseif ~isempty(val)
                %constant attribute
                obj.value = val;
                obj.readonly = true;
            else
                obj.value = [];
                obj.readonly = false;
            end
            
            dims = source.get('dims');
            shape = source.get('shape');
            if isempty(shape)
                obj.shape = '1';
                obj.dimnames = {obj.name};
            else
                [obj.shape, obj.dimnames] = file.procdims(shape, dims);
                if ischar(obj.shape)
                    obj.scalar = ~strcmp(obj.shape, 'Inf');
                elseif iscellstr(obj.shape)
                    obj.scalar = ~any(strcmp(obj.shape, 'Inf'));
                end
            end
            
            obj.dtype = file.mapType(source.get('dtype'));
        end
    end
end