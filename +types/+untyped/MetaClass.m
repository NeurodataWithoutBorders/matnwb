classdef MetaClass < handle
    methods
        function obj = MetaClass(varargin)
        end
        
        function refs = export(obj, fid, fullpath, refs)
            %find reference properties
            propnames = properties(obj);
            props = cell(size(propnames));
            for i=1:length(propnames)
                props{i} = obj.(propnames{i});
            end
            
            try
                resolveReferences();
                writeData();
            catch ME
                if strcmp(ME.stack(2).name, 'getRefData') && ...
                        endsWith(ME.stack(1).file, ...
                        fullfile({'+H5D','+H5R'}, {'open.m', 'create.m'}))
                    refs(end+1) = {fullpath};
                    return;
                else
                    rethrow(ME);
                end
            end

            writeAttributes();
            
            function resolveReferences()
                refProps = cellfun('isclass', props, 'types.untyped.ObjectView') |...
                    cellfun('isclass', props, 'types.untyped.RegionView');
                props = props(refProps);
                for i=1:length(props)
                    io.getRefData(fid, props{i});
                end
            end
            
            function writeData()
                if isa(obj, 'hdmf_common.Container') || isa(obj, 'hdmf_common.CSRMatrix')
                    io.writeGroup(fid, fullpath);
                    return;
                end
                if isa(obj.data, 'types.untyped.DataStub')
                    refs = obj.data.export(fid, fullpath, refs);
                elseif istable(obj.data) || isstruct(obj.data) ||...
                        isa(obj.data, 'containers.Map')
                    io.writeCompound(fid, fullpath, obj.data);
                else
                    io.writeDataset(fid, fullpath, obj.data, 'forceArray');
                end
            end
            
            function writeAttributes()
                if isa(obj, 'NwbFile')
                    io.writeAttribute(fid,'/namespace', 'core');
                    io.writeAttribute(fid,'/neurodata_type', 'NWBFile');
                else
                    namespacePath = [fullpath '/namespace'];
                    neuroTypePath = [fullpath '/neurodata_type'];
                    dotparts = split(class(obj), '.');
                    namespace = dotparts{2};
                    classtype = dotparts{3};
                    io.writeAttribute(fid, namespacePath, namespace);
                    io.writeAttribute(fid, neuroTypePath, classtype);
                end
                uuid = char(java.util.UUID.randomUUID().toString());
                io.writeAttribute(fid, [fullpath '/object_id'], uuid);
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