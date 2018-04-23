classdef Link < handle
    properties(SetAccess=private)
        doc;
        name;
        required;
        type;
    end
    
    methods
        function obj = Link(source)
            obj.doc = [];
            obj.name = [];
            obj.required = [];
            obj.type = [];
            if nargin < 1
                return;
            end
            
            obj.doc = source.get('doc');
            obj.name = source.get('name');
            obj.type = source.get('target_type');
            
            quantity = source.get('quantity');
            obj.required = isempty(quantity) || strcmp(quantity, '+');
        end
    end
end