classdef nwb
    properties %meta
        filename;
    end
    
    properties %attributes
        attributes = struct('namespace', [], 'source', []);
        general = struct();
    end
    
    properties %datasets
        file_create_date = [];
        identifier = [];
        nwb_version = [];
        session_description = [];
        session_start_time = [];
    end
    
    properties %grouped datasets
        acq_images = struct();
        acq_timeseries = struct();
        epochs = struct();
        processing = struct();
        stimulus_presentation = struct();
        stimulus_templates = struct();
        analysis = struct();
    end
    
    methods
        function obj = nwb(filename)
            function group = processGroups(path)
                info = h5info(filename, path);
                group = h5helper.importH5Groups(info.Groups, filename);
            end
            root = h5info(filename);
            obj.filename = filename;
            obj.attributes = root.Attributes;
            %we assume that these Datasets satisfy MATLAB struct name
            %constraints.
            for i=1:length(root.Datasets)
                name = root.Datasets(i).Name;
                obj.(name) = h5read(filename, strcat('/', name));
            end
            
            %process general
            %datasets in the first level should work with MATLAB struct
            %name constraints
            gen = h5info(filename, '/general');
            if ~isempty(gen.Datasets)
                gen_ds = gen.Datasets;
                for i=1:length(gen_ds)
                    name = gen_ds(i).Name;
                    obj.general.datasets.(name) =...
                        h5read(filename, strcat('/general', '/', name));
                end
            end
            
            %we assume that there is only one level of groups so further
            %recursion is unnecessary.
            %we CANNOT assume that the NWBContainer names satisfy MATLAB
            %struct name constraints
            obj.general.groups = struct();
            if ~isempty(gen.Groups)
                gen_g = gen.Groups;
                for i=1:length(gen_g)
                    group = gen_g(i);
                    [~, name, ~] = fileparts(group.Name);
                    if strcmp(name, 'subject')
                        %subject datasets are named and satisfy MATLAB
                        %constraints
                        for i=1:length(group.Datasets)
                            ds = group.Datasets(i);
                            [~, ds_nm, ~] = fileparts(ds.Name);
                            obj.general.groups.subject.(ds_nm) =...
                                h5read(filename, strcat(group.Name, '/', ds.Name));
                        end
                    elseif strcmp(name, 'intracellular_ephys')
                        %intracellular ephys has BOTH NWBContainers and a
                        %'filtering' dataset.
                        i_e = struct();
                        if ~isempty(group.Datasets)
                            i_e.filtering =...
                                h5read(filename, strcat(group.Name, '/filtering'));
                        end
                        i_e.electrode_groups =...
                            h5helper.importH5Groups(groups.Groups, filename);
                        obj.general.groups.intracellular_ephys = i_e;
                    else
                        obj.general.groups.(name) =...
                            h5helper.importH5Groups(group.Groups, filename);
                    end
                end
            end
            
            %process dataset groups
            obj.acq_images = processGroups('/acquisition/images');
            obj.acq_timeseries = processGroups('/acquisition/timeseries');
            obj.epochs = processGroups('/epochs');
            obj.processing = processGroups('/processing');
            obj.stimulus_presentation = processGroups('/stimulus/presentation');
            obj.stimulus_templates = processGroups('/stimulus/templates');
        end
        
        function export(obj, filename)
            %TODO
            file = createEmpty(filename);
            
        end
    end
    
    methods(Access=private)
        function outobj = exportProperties(obj, propname)
            prop = obj.(propname);
            outobj = [];
            if ~isempty(prop)
                for i=1:length(prop)
                    outobj = prop(i).export();
                end
            end
        end
        function fileobj = createEmpty(filename)
            %generate an empty nwb file and returns ids to relevant groups
            %and datasets
            
            fileobj = struct();
            
            %string
            string_id = H5T.copy('H5T_C_S1');
            H5T.set_size(string_id, 'H5T_VARIABLE');
            
            %file
            fid = H5F.create(filename);
            
            %root groups
            dirs = struct('acquisition', [], 'analysis', [], 'epochs', [],...
                'processing', [], 'general', [], 'stimulus', []);
            dirnames = fieldnames(dirs);
            for i=1:length(dirnames)
                dn = dirnames{i};
                dirs.(dn) = h5helper.createGroup(fid, strcat('/',dn));
            end
            
            dirs.images = h5helper.createGroup(dirs.acquisition, 'images');
            dirs.timeseries = h5helper.createGroup(dirs.acquisition, 'timeseries');
            
            dirs.presentation = h5helper.createGroup(dirs.stimulus, 'presentation');
            dirs.templates = h5helper.createGroup(dirs.stimulus, 'templates');
            
            fileobj.groups = dirs;
            
            %attribute
            
            fileobj.attr.help = h5helper.createAttr(fid, 'help', string_id, 'H5S_SCALAR');
            fileobj.attr.namespace = h5helper.createAttr(fid, 'namespace', string_id, 'H5S_SCALAR');
            fileobj.attr.neurodata_type = h5helper.createAttr(fid, 'neurodata_type', string_id, 'H5S_SCALAR');
            fileobj.attr.source = h5helper.createAttr(fid, 'source', string_id, 'H5S_SCALAR');
            
            H5A.write(fileobj.attr.help, string_id,...
                {'an NWB:N file for storing cellular-based neurophysiology data'});
            H5A.write(fileobj.attr.namespace, string_id, {''});
            H5A.write(fileobj.attr.neurodata_type, string_id, {'NWBFile'});
            H5A.write(fileobj.attr.source, string_id, {''});
            
            %datasets
            fileobj.ds.file_create_date = h5helper.createDataset(fid, 'file_create_date', string_id, 1);
            fileobj.ds.identifier = h5helper.createDataset(fid, 'identifier', string_id, 1);
            fileobj.ds.nwb_version = h5helper.createDataset(fid, 'nwb_version', string_id, 1);
            fileobj.ds.session_description = h5helper.createDataset(fid, 'session_description', string_id, 1);
            fileobj.ds.session_start_time = h5helper.createDataset(fid, 'session_start_time', string_id, 1);
            
            h5helper.writeDataset(fileobj.ds.file_create_date, {datestr(datetime('now'))});
            h5helper.writeDataset(fileobj.ds.identifier, {''});
            h5helper.writeDataset(fileobj.ds.nwb_version, {'1.0.6'});
            h5helper.writeDataset(fileobj.ds.session_description, {''});
            h5helper.writeDataset(fileobj.ds.session_start_time, {''});
            
            fileobj.file = fid;
        end
    end
end