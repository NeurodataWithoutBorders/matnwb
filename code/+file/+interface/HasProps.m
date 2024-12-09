classdef HasProps < matlab.mixin.Heterogeneous
    methods (Abstract)
        props = getProps(obj);
    end
end

