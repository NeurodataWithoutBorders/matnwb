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
                obj.embedSpecifications(fid);
                refs = export@types.core.NWBFile(obj, fid, '/', {});
                obj.resolveReferences(fid, refs);
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
    
    %% PRIVATE
    methods(Access=private)
        function resolveReferences(obj, fid, references)
            while ~isempty(references)
                resolved = false(size(references));
                for iRef = 1:length(references)
                    refSource = references{iRef};
                    sourceObj = obj.resolve(refSource);
                    unresolvedRefs = sourceObj.export(fid, refSource, {});
                    exportSuccess = isempty(unresolvedRefs);
                    resolved(iRef) = exportSuccess;
                end
                
                if any(resolved)
                    references(resolved) = [];
                else
                    errorFormat =...
                        'Could not resolve paths for the following reference(s):\n%s';
                    unresolvedRefs = strjoin(references, newline);
                    error(errorFormat, file.addSpaces(unresolvedRefs, 4));
                end
            end
        end
        
        function embedSpecifications(~, fid)
            specLocation = '/specifications';
            io.writeGroup(fid, specLocation);
            specView = types.untyped.ObjectView(specLocation);
            io.writeAttribute(fid, '/.specloc', specView);
            
            JsonData = schemes.exportJson();
            for iJson = 1:length(JsonData)
                JsonDatum = JsonData(iJson);
                schemaLocation =...
                    strjoin({specLocation, JsonDatum.name, JsonDatum.version}, '/');
                io.writeGroup(fid, schemaLocation);
                Json = JsonDatum.json;
                schemeNames = keys(Json);
                for iScheme = 1:length(schemeNames)
                    name = schemeNames{iScheme};
                    path = [schemaLocation '/' name];
                    io.writeDataset(fid, path, Json(name));
                end
            end
        end
    end
end
