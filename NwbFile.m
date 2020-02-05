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
    
    methods (Static, Access = private)
        function embed_spec(File)
            Attributes = File.get_all_attributes();
            if any({Attributes.name}, '.specloc')
                return; % we can't hope to amend this.
            end
            
            Attribute = File.add_attribute('.specloc');
            Root = File.add_group('specification');
            View = types.untyped.ObjectView(Root.get_name());
            Attribute.write(View.serialize(File));
            
            JsonData = schemes.exportJson();
            for i_json = 1:length(JsonData)
                NamespaceData = JsonData(i_json);
                NamespaceGroup = Root.add_group(NamespaceData.name);
                NamespaceVersion = NamespaceGroup.add_group(NamespaceData.version);
                Json = NamespaceData.json;
                
                scheme_names = Json.keys();
                for i_scheme = 1:length(scheme_names)
                    name = scheme_names{i_scheme};
                    SchemeDataset = NamespaceVersion.add_dataset(name);
                    SchemeDataset.write(Json(name));
                end
            end
        end
    end
    
    methods
        function obj = NwbFile(varargin)
            obj = obj@types.core.NWBFile(varargin{:});
        end
        
        function export(obj, filename)
            %add to file create date
            current_time = datetime('now');
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
            
            if 2 == exist(filename, 'file')
                File = h5.File.create(filename);
            else
                File = h5.File.open(filename);
            end
            
            try
                NwbFile.embed_spec(File);
                MissingViews = export@types.core.NWBFile(obj, obj, '/');
                obj.resolveReferences(File, MissingViews);
            catch ME
                obj.file_create_date(end) = [];
                rethrow(ME);
            end
        end
        
        function o = resolve(obj, path)
            o = io.resolvePath(obj, path);
        end
    end
    
    %% PRIVATE
    methods(Access=private)
        function resolveReferences(obj, File, Views)
            while ~isempty(Views)
                resolved = false(size(Views));
                for i_view = 1:length(Views)
                    View = Views{i_view};
                    
                    Object = File.get_descendent(View.get_destination());
                    sourceObj = obj.resolve(View);
                    unresolvedRefs = sourceObj.export(fid, View, {});
                    exportSuccess = isempty(unresolvedRefs);
                    resolved(i_view) = exportSuccess;
                end
                
                if any(resolved)
                    Views(resolved) = [];
                else
                    errorFormat =...
                        'Could not resolve paths for the following reference(s):\n%s';
                    unresolvedRefs = strjoin(Views, newline);
                    error(errorFormat, file.addSpaces(unresolvedRefs, 4));
                end
            end
        end
    end
end
