classdef MetaClass < handle
    properties (Hidden, SetAccess = private)
        metaClass_fullPath;
    end
    
    methods
        function obj = MetaClass(varargin)
        end
    end
    
    methods (Access = private)
        function refs = write_base(obj, fid, fullpath, refs)
            if isa(obj, 'types.untyped.GroupClass')
                io.writeGroup(fid, fullpath);
                return;
            end
            
            try
                if isa(obj.data, 'types.untyped.DataStub')...
                        || isa(obj.data, 'types.untyped.DataPipe')
                    refs = obj.data.export(fid, fullpath, refs);
                elseif istable(obj.data) || isstruct(obj.data) ||...
                        isa(obj.data, 'containers.Map')
                    io.writeCompound(fid, fullpath, obj.data);
                else
                    io.writeDataset(fid, fullpath, obj.data, 'forceArray');
                end
            catch ME
                refs = obj.captureReferenceErrors(ME, fullpath, refs);
            end
        end
        
        function refs = captureReferenceErrors(~, ME, fullpath, refs)
            if any(strcmp(ME.identifier, {...
                    'NWB:getRefData:InvalidPath',...
                    'NWB:ObjectView:MissingPath'}))
                refs(end+1) = {fullpath};
            else
                rethrow(ME);
            end
        end
    end
    
    methods
        function refs = export(obj, fid, fullpath, refs)
            obj.metaClass_fullPath = fullpath;
            %find reference properties
            propnames = properties(obj);
            props = cell(size(propnames));
            for i=1:length(propnames)
                props{i} = obj.(propnames{i});
            end
            
            refProps = cellfun('isclass', props, 'types.untyped.ObjectView') |...
                cellfun('isclass', props, 'types.untyped.RegionView');
            props = props(refProps);
            for i=1:length(props)
                try
                    io.getRefData(fid, props{i});
                catch ME
                    refs = obj.captureReferenceErrors(ME, fullpath, refs);
                end
            end
            
            refLen = length(refs);
            refs = obj.write_base(fid, fullpath, refs);
            if refLen ~= length(refs)
                return;
            end
            
            uuid = char(java.util.UUID.randomUUID().toString());
            if isa(obj, 'NwbFile')
                io.writeAttribute(fid, '/namespace', 'core');
                io.writeAttribute(fid, '/neurodata_type', 'NWBFile');
                io.writeAttribute(fid, '/object_id', uuid);
            else
                namespacePath = [fullpath '/namespace'];
                neuroTypePath = [fullpath '/neurodata_type'];
                uuidPath = [fullpath '/object_id'];
                dotparts = split(class(obj), '.');
                namespace = strrep(dotparts{2}, '_', '-');
                classtype = dotparts{3};
                io.writeAttribute(fid, namespacePath, namespace);
                io.writeAttribute(fid, neuroTypePath, classtype);
                io.writeAttribute(fid, uuidPath, uuid);
            end
        end
        
        function obj = loadAll(obj)
            propnames = properties(obj);
            for i=1:length(propnames)
                prop = obj.(propnames{i});
                if isa(prop, 'types.untyped.DataStub')
                    obj.(propnames{i}) = prop.load();
                end
            end
        end
    end
end