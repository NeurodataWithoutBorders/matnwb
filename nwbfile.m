classdef nwbfile < types.core.NWBFile
    % nwbfile Root object representing data read from an NWB file.
    %
    % Requires that core and extension NWB types have been generated
    % and reside in a 'types' package on the matlab path.
    %
    % Example. Construct an object from scratch for export:
    %    nwb = nwbfile;
    %    nwb.epochs = types.untyped.Group;
    %    nwb.epochs.stim = types.Epoch;
    %    nwbExport(nwb, 'epoch.nwb');
    %
    % See also NWBREAD, GENERATECORE, GENERATEEXTENSIONS
    methods
        function obj = nwbfile(varargin)
            obj = obj@types.core.NWBFile(varargin{:});
            obj.nwb_version = '1.2.0';
        end
        
        function export(obj, filename)
            if exist(filename, 'file')
                warning('Overwriting %s', filename);
                delete(filename);
            end
            modtime = datestr(datetime, 30);
            if ischar(obj.file_create_date)
                obj.file_create_date = {obj.file_create_date modtime};
            else
                obj.file_create_date = [obj.file_create_date {modtime}];
            end
            fid = H5F.create(filename);
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
        end
        
        function o = resolve(obj, path)
            o = io.resolvePath(obj, path);
        end
    end
end