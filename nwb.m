classdef nwb
    properties %meta
        filename;
    end
    
    properties %attributes
        attributes = struct('namespace', [], 'source', []);
        general = struct([]);
    end
    
    properties %values
        identifier;
        nwb_version;
        session_description;
        session_start_time;
    end
    
    properties %datasets
        acq_images;
        acq_timeseries;
        epochs;
        processing;
        specifications;
        optogenetics;
        optophysiology;
        devices;
        extracellular_ephys;
        intracellular_ephys;
        stimulus_presentation;
        stimulus_templates;
        analysis;
    end
    
    methods %public
        function obj = nwb(filename)
            root = h5info(filename);
            obj.filename = filename;
            obj.attributes = root.Attributes;
            for i=1:length(root.Datasets)
                name = root.Datasets(i).Name;
                obj.(name) = h5read(filename, strcat('/', name));
            end
            
            %process general
            gen = h5info(filename, '/general');
            if ~isempty(gen.Datasets)
                gen_ds = gen.Datasets;
                for i=1:length(gen_ds)
                    name = gen_ds(i).Name;
                    obj.general.(name) = h5read(filename, strcat('/general', '/', name));
                end
            end
            if ~isempty(gen.Groups)
            end
            
            %process dataset groups
            acq_img = h5info(filename, '/acquisition/images');
            
            acq_ts = h5info(filename, '/acquisition/timeseries');
            epochs = h5info(filename, '/epochs');
        end
        
        function export(obj, filename)
            file = create_empty(filename);
        end
    end
    
    methods %private
        function fileobj = create_empty(filename)
            %generate an empty nwb file
            
            fileobj = struct([]);
            
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
                dirs.(dn) = create_group(fid, strcat('/',dn));
            end
            
            dirs.images = create_group(dirs.acquisition, 'images');
            dirs.timeseries = create_group(dirs.acquisition, 'timeseries');
            
            dirs.presentation = create_group(dirs.stimulus, 'presentation');
            dirs.templates = create_group(dirs.stimulus, 'templates');
            
            %attribute
            fileobj.attr.help = create_attr(fid, 'help', string_id);
            fileobj.attr.namespace = create_attr(fid, 'namespace', string_id);
            fileobj.attr.neurodata_type = create_attr(fid, 'neurodata_type', string_id);
            fileobj.attr.source = create_attr(fid, 'source', string_id);
            
            H5A.write(fileobj.attr.help, string_id,...
                {'an NWB:N file for storing cellular-based neurophysiology data'});
            H5A.write(fileobj.attr.namespace, string_id, {''});
            H5A.write(fileobj.attr.neurodata_type, string_id, {'NWBFile'});
            H5A.write(fileobj.attr.source, string_id, {''});
            
            %link
            % create_softlink('/g1', analysis, 'l1');
            % create_externlink('testlink.h5', '/linked', analysis, 'l2');
            
            %datasets
            fileobj.ds.file_create_date = create_dataset(fid, 'file_create_date', string_id, 1);
            fileobj.ds.identifier = create_dataset(fid, 'identifier', string_id, 1);
            fileobj.ds.nwb_version = create_dataset(fid, 'nwb_version', string_id, 1);
            fileobj.ds.session_description = create_dataset(fid, 'session_description', string_id, 1);
            fileobj.ds.session_start_time = create_dataset(fid, 'session_start_time', string_id, 1);
            
            write_dataset(fileobj.ds.file_create_date, {datestr(datetime('now'))});
            write_dataset(fileobj.ds.identifier, {''});
            write_dataset(fileobj.ds.nwb_version, {'1.0.6'});
            write_dataset(fileobj.ds.session_description, {''});
            write_dataset(fileobj.ds.session_start_time, {''});
      
            dirnames = fieldnames(dirs);
            for i=1:length(dirnames)
                H5G.close(dirs.(dirnames{i}));
            end
            fileobj.file = fid;
        end
        function gid = create_group(loc_id, name)
            plist = 'H5P_DEFAULT';
            gid = H5G.create(loc_id, name, plist, plist, plist);
        end
        function attr_id = create_attr(loc_id, name, type_id)
            sid = H5S.create('H5S_SCALAR');
            pid = H5P.create('H5P_ATTRIBUTE_CREATE');
            attr_id = H5A.create(loc_id, name, type_id, sid, pid);
            H5S.close(sid);
        end
        function did = create_dataset(loc_id, name, type_id, dimensions)
            sid = H5S.create_simple(length(dimensions), dimensions, dimensions);
            did = H5D.create(loc_id, name, type_id, sid, 'H5P_DEFAULT');
        end
    end
end