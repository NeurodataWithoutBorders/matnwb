classdef NwbFile < types.core.NWBFile
    % NWBFILE Root object representing data read from an NWB file.
    %
    % Requires that core and extension NWB types have been generated
    % and reside in a 'types' package on the matlab path.
    %
    % Example. Construct an object from scratch for export:
    %    nwb = NwbFile;
    %    nwb.epochs = types.core.Epochs;
    %    nwbExport(nwb, 'epoch.nwb');
    %
    % See also NWBREAD, GENERATECORE, GENERATEEXTENSION
    
    methods
        function obj = NwbFile(varargin)
            obj = obj@types.core.NWBFile(varargin{:});
        end
        
        function export(obj, filename)
            %add to file create date
            current_time = datetime('now', 'TimeZone', 'local');
            if isa(obj.file_create_date, 'types.untyped.DataStub')
                obj.file_create_date = obj.file_create_date.load();
            end

            if isempty(obj.file_create_date)
                obj.file_create_date = current_time;
            elseif iscell(obj.file_create_date)
                obj.file_create_date(end+1) = {current_time};
            else
                obj.file_create_date = {obj.file_create_date current_time};
            end
            
            %equate reference time to session_start_time if empty
            if isempty(obj.timestamps_reference_time)
                obj.timestamps_reference_time = obj.session_start_time;
            end
            
            try
                output_file_id = H5F.create(filename);
            catch ME % if file exists, open and edit
                isLibraryError = strcmp(ME.identifier,...
                    'MATLAB:imagesci:hdf5lib:libraryError');
                isFileExistsError = isLibraryError &&...
                    contains(ME.message, '''File exists''');
                if isFileExistsError
                    output_file_id = H5F.open(filename, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
                else
                   rethrow(ME); 
                end
            end
            
            try
                refs = export@types.core.NWBFile(obj, output_file_id, '/', {});
                
                loop_offset = 0;
                while ~isempty(refs)
                    if loop_offset >= length(refs)
                        error('Could not resolve paths for the following reference(s):\n%s',...
                            file.addSpaces(strjoin(refs, newline), 4));
                    end
                    reference_path = refs{1};
                    refs(1) = []; %pop
                    obj_to_write = obj.resolve(reference_path);
                    
                    if isempty(obj_to_write.export(output_file_id, reference_path, {}))
                        loop_offset = 0;
                    else
                        refs = [refs reference_path]; %push back
                        loop_offset = loop_offset + 1;
                    end
                end
                H5F.close(output_file_id);
            catch ME
                obj.file_create_date(end) = [];
                H5F.close(output_file_id);
                rethrow(ME);
            end
        end
        
        function o = resolve(obj, path)
            o = io.resolvePath(obj, path);
        end
    end
end
