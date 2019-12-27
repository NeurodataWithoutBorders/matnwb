classdef IsHdfData
    %ISFILEDATA This object is associated with readable/writable data.
    
    methods (Abstract)
        data = read(obj);
        write(obj, data);
    end
end

