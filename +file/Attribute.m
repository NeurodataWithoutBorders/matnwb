classdef Attribute < handle
    properties(SetAccess=private)
        name; %attribute key
        doc; %doc string
        required; %bool regarding whether or not this Attribute is required for class
        value; %Value
        readonly; %determines whether value can be changed or not
        dtype; %type of value
    end
    
    methods
        function obj = Attribute(source)
            %defaults
            obj.name = '';
            obj.doc = '';
            obj.required = true;
            obj.value = [];
            obj.readonly = false;
            obj.dtype = [];
            
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
            
            obj.dtype = file.mapType(source.get('dtype'));
        end
    end
end