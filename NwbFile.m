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
            if 2 == exist(filename, 'file')
                warning('Overwriting %s', filename);
                delete(filename);
            end
            
            %add to file create date
            dt = datetime('now', 'TimeZone', 'local');
            if isempty(obj.file_create_date)
                obj.file_create_date = dt;
            elseif iscell(obj.file_create_date)
                obj.file_create_date(end+1) = {dt};
            else
                obj.file_create_date = {obj.file_create_date dt};
            end
            
            %equate reference time to session_start_time if empty
            if isempty(obj.timestamps_reference_time)
                obj.timestamps_reference_time = obj.session_start_time;
            end
            
            fid = H5F.create(filename);
            try
                refs = export@types.core.NWBFile(obj, fid, '/', {});
                
                loop_offset = 0;
                while ~isempty(refs)
                    if loop_offset >= length(refs)
                        error('Could not resolve paths for the following reference(s):\n%s',...
                            file.addSpaces(strjoin(refs, newline), 4));
                    end
                    src = refs{1};
                    refs(1) = []; %pop
                    srcobj = obj.resolve(src);
                    
                    if isempty(srcobj.export(fid, src, {}))
                        loop_offset = 0;
                    else
                        refs = [refs src]; %push back
                        loop_offset = loop_offset + 1;
                    end
                end
                H5F.close(fid);
            catch ME
                obj.file_create_date(end) = [];
                H5F.close(fid);
                rethrow(ME);
            end
        end
        
        function o = resolve(obj, path)
            o = io.resolvePath(obj, path);
        end
    end
end
