classdef Primitives
    enumeration
        Groups('groups')
        Datasets('datasets')
        Attributes('attributes')
        Links('links')
    end

    properties
        Key
    end

    methods
        function obj = Primitives(keyName)
            obj.Key = keyName;
        end
    end
end
