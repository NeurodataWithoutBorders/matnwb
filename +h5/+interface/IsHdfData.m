classdef IsHdfData < handle
    %ISFILEDATA This object is associated with readable/writable data.
    
    methods (Abstract)
        Type = get_type(obj);
        data = read(obj, varargin);
        write(obj, data);
    end
end

