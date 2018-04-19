classdef MetaClass < handle
    methods
        function obj = MetaClass(varargin)
        end
        
        function export(~, loc_id)
            [fp, ndt, ~] = fileparts(mfilename('fullpath'));
            [~, namespace, ~] = fileparts(fp);
            h5util.writeAttribute(loc_id, 'namespace', ndt(2:end), 'string');
            h5util.writeAttribute(loc_id, 'neurodata_type', namespace(2:end), 'string');
        end
    end
end