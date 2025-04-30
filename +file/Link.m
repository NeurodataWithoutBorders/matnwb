classdef Link < file.interface.HasQuantity
    properties (SetAccess = private)
        doc;
        name;
        required;
        type;
    end
    
    methods
        function obj = Link(source)
            obj.doc = [];
            obj.name = [];
            obj.required = true;
            obj.type = [];
            if nargin < 1
                return;
            end
            
            obj.doc = source('doc');
            obj.name = source('name');
            obj.type = source('target_type');
            obj.required = obj.isRequired(source);
        end
    end
end