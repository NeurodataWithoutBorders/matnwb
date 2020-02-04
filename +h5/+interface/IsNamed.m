classdef IsNamed < h5.interface.HasId
    %ISNAMED This class has a name that is gettable.
    
    methods
        function name = get_name(obj)
            name = H5I.get_name(obj.get_id());
        end
    end
end

