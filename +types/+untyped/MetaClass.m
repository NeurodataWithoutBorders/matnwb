classdef MetaClass < handle
    methods
        function obj = MetaClass(varargin)
        end
        
        function refs = export(obj, fid, fullpath, refs)
            
            if isa(obj, 'nwbfile')
                io.writeAttribute(fid, 'char', '/namespace', 'core');
                io.writeAttribute(fid, 'char', '/neurodata_type', 'NWBFile');
                return;
            end
            
            namespacePath = [fullpath '/namespace'];
            neuroTypePath = [fullpath '/neurodata_type'];
            dotparts = split(class(obj), '.');
            namespace = dotparts{2};
            classtype = dotparts{3};
            io.writeAttribute(fid, 'char', namespacePath, namespace);
            io.writeAttribute(fid, 'char', neuroTypePath, classtype);
        end
        
        function data = loadAll(obj)
            assert(isa(obj, 'types.core.NWBData'),...
                'load() is not supported for non-dataset objects');
            if isa(obj.data, 'types.untyped.DataStub')
                obj.data = obj.data.load();
            end
            data = obj.data;
        end
    end
end