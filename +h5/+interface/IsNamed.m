classdef IsNamed
    %ISNAMED This class has a name that is gettable.
    
    methods (Abstract)
        name = get_name(obj);
    end
end

