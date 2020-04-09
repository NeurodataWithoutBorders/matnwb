classdef Filter < handle
    %FILTER Filters used in datapipe creation
    methods (Abstract)
        addTo(obj, dcpl);
        getName(obj);
    end
end