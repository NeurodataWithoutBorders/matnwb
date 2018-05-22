classdef MetaClass < handle
    methods
        function obj = MetaClass(varargin)
        end
        
        function refs = export(obj, ~, loc_id, ~, ~, refs)
            if isa(obj, 'nwbfile')
                io.writeAttribute(loc_id, 'char', 'namespace', 'core');
                io.writeAttribute(loc_id, 'char', 'neurodata_type', 'NWBFile');
                return;
            end
            
            dotparts = split(class(obj), '.');
            namespace = dotparts{2};
            classtype = dotparts{3};
            io.writeAttribute(loc_id, 'char', 'namespace', namespace);
            io.writeAttribute(loc_id, 'char', 'neurodata_type', classtype);
        end
    end
end