classdef Link < file.interface.HasQuantity
    properties (SetAccess = private)
        doc;
        name;
        required;
        type;
        scalar;
    end
    
    methods
        function obj = Link(source)
            obj.doc = [];
            obj.name = [];
            obj.required = true;
            obj.type = [];
            obj.scalar = true;

            if nargin < 1
                return;
            end

            % If the name is missing, we use the target type for the name
            if isKey(source, 'name')
                obj.name = source('name');
            else
                obj.name = lower(source('target_type'));
            end
            
            obj.doc = source('doc');
            obj.type = source('target_type');
            obj.required = obj.isRequired(source);
            obj.scalar = obj.isScalar(source);
        end
    end
end
