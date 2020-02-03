classdef IsObject < handle & matlab.mixin.Heterogeneous & h5.interface.IsNamed
    %ISOBJECT This object can be a linkable object as per H5.
    
    methods % IsNamed
        function name = get_name(obj)
            name = H5I.get_name(obj.get_id());
        end
    end
end