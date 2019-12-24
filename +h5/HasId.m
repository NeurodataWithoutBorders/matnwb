classdef HasId < handle
    %HASID Interface for H5 objects with a representable id
    
    methods (Abstract)
        id = get_id(obj);
    end
end

