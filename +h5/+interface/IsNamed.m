classdef IsNamed < h5.interface.HasId
    %ISNAMED This class has a name that is gettable.
    
    methods (Abstract)
        name = get_name(obj);
    end
end

