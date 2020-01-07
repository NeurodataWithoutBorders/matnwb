classdef Exportable < handle
    %EXPORTABLE this object can be exported to an H5 format.
    
    methods (Abstract)
        MissingViews = export(obj, Parent, name);
    end
end

