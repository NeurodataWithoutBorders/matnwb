classdef Pipe < handle
    %PIPE Generic data pipe.  Only here for validation's sake.
    
    methods (Abstract)
        pipe = write(obj, fid, fullpath);
        append(obj, data);
        config = getConfig(obj);
    end
end

