classdef nwbfile < types.core.NWBFile
    % nwbfile Root object representing data read from an NWB file.
    %
    % Requires that core and extension NWB types have been generated
    % and reside in a 'types' package on the matlab path.
    %
    % Example. Construct an object from scratch for export:
    %    nwb = nwbfile;
    %    nwb.epochs = types.core.Epochs;
    %    nwbExport(nwb, 'epoch.nwb');
    %
    % See also NWBREAD, GENERATECORE, GENERATEEXTENSIONS
    methods
        function obj = nwbfile(varargin)
            obj = obj@types.core.NWBFile(varargin{:});
        end
        
        function export(obj, filename)
            if 2 == exist(filename, 'file')
                warning('Overwriting %s', filename);
                delete(filename);
            end
            
            %add to file create date
            modtime = datestr(datetime, 30);
            if isempty(obj.file_create_date)
                obj.file_create_date = modtime;
            elseif ischar(obj.file_create_date)
                if ismatrix(obj.file_create_date)
                    %convert multidim array to cell array
                    dims = size(obj.file_create_date);
                    obj.file_create_date = mat2cell(obj.file_create_date,...
                        ones(dims(1), 1), dims(2));
                else
                    obj.file_create_date = {obj.file_create_date};
                end
                obj.file_create_date = [obj.file_create_date; {modtime}];
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