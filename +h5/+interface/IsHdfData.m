classdef IsHdfData < h5.interface.HasSpace & h5.interface.HasType
    %ISFILEDATA This object is associated with readable/writable data.
    
    methods (Abstract)
        data = read(obj, varargin);
        write(obj, data, varargin);
    end
end

