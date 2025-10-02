classdef NwbFile < types.core.NWBFile
% NWBFILE - Root object representing an NWB file.
%
% Requires that core and extension NWB types have been generated
% and reside in a ``+types`` namespace on the MATLAB search path.
%
% Usage:
%  Example 1 - Construct a simple NwbFile object for export::
%
%    nwb = NwbFile;
%    nwb.epochs = types.core.Epochs;
%    nwbExport(nwb, 'epoch.nwb');
%
% See also:
%   nwbRead, generateCore, generateExtension

    methods
        function obj = NwbFile(propValues)
        % NWBFILE - Create an NWB File object

            arguments
                propValues.?types.core.NWBFile
                propValues.nwb_version
            end
            nameValuePairs = namedargs2cell(propValues);
            obj = obj@types.core.NWBFile(nameValuePairs{:});
            if strcmp(class(obj), 'NwbFile') %#ok<STISA>
                cellStringArguments = convertContainedStringsToChars(nameValuePairs(1:2:end));
                types.util.checkUnset(obj, unique(cellStringArguments));
            end
        end

        function export(obj, filename, mode)
        % EXPORT - Export NWB file object

            arguments
                obj (1,1) NwbFile
                filename (1,1) string
                mode (1,1) string {mustBeMember(mode, ["edit", "overwrite"])} = "edit"
            end

            % add to file create date
            if isa(obj.file_create_date, 'types.untyped.DataStub')
                obj.file_create_date = obj.file_create_date.load();
            end

            current_time = {datetime('now', 'TimeZone', 'local')};
            if isempty(obj.file_create_date)
                obj.file_create_date = current_time;
            elseif iscell(obj.file_create_date)
                obj.file_create_date(end+1) = current_time;
            else
                % obj.file_create_date could be a datetime array
                obj.file_create_date = num2cell(obj.file_create_date);
                obj.file_create_date(end+1) = current_time;
            end

            obj.addWasGeneratedBy()

            % equate reference time to session_start_time if empty
            if isempty(obj.timestamps_reference_time)
                obj.timestamps_reference_time = obj.session_start_time;
            end

            isEditingFile = false;

            if isfile(filename)
                if mode == "edit"
                    output_file_id = H5F.open(filename, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
                    isEditingFile = true;
                elseif mode == "overwrite"
                    output_file_id = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
                end
            else
                output_file_id = H5F.create(filename);
            end

            try
                obj.embedSpecifications(output_file_id)
                refs = export@types.core.NWBFile(obj, output_file_id, '/', {});
                obj.resolveReferences(output_file_id, refs);
                H5F.close(output_file_id);
            catch ME
                obj.file_create_date(end) = [];
                H5F.close(output_file_id);
                if ~isEditingFile
                    delete(filename);
                end
                rethrow(ME);
            end
        end

        function datasetConfig = applyDatasetSettingsProfile(obj, profile, options)
        % APPLYDATASETSETTINGSPROFILE - Configure datasets using predefined settings profile
        %
        % Syntax:
        %  nwb.applyDatasetSettingsProfile(profile) applies a dataset
        %  configuration profile to the nwb-file ``nwb``. Available profiles:
        %  "default", "cloud", "archive". This will configure datasets in
        %  the NwbFile object for chunking and compression.
        % 
        % Input Arguments:
        %  - obj (NwbFile) - An instance of the NwbFile class.
        % 
        %  - profile (ConfigurationProfile) - 
        %   Specifies the settings profile to use. Default is "none".
        %
        % Name-Value Arguments:
        %  - OverrideExisting (logical) - 
        %   This boolean determines if existing DataPipe objects in the
        %   file will be reconfigured with the provided options. Default is
        %   false. **Important**: This does not work for DataPipes that has
        %   previously been exported to file.
        % 
        % Output Arguments:
        %  - datasetConfig - 
        %   (Optional) The configuration settings applied to the dataset.
        %
        % See also:
        %   io.config.enum.ConfigurationProfile
        %   NwbFile.applyDatasetSettings

            arguments
                obj (1,1) NwbFile
                profile (1,1) io.config.enum.ConfigurationProfile = "none"
                options.OverrideExisting (1,1) logical = false
            end
            
            datasetConfig = io.config.readDatasetConfiguration(profile);
            nvPairs = namedargs2cell(options);
            obj.applyDatasetSettings(datasetConfig, nvPairs{:});
            if ~nargout
                clear datasetConfig
            end
        end


        function datasetConfig = applyDatasetSettings(obj, settingsReference, options)
        % APPLYDATASETSETTINGS - Configure datasets using NWB dataset settings
        %
        % Syntax:
        %  nwb.applyDatasetSettings(settingsReference) applies a dataset
        %  configuration profile to the nwb-file ``nwb``. This method
        %  accepts the filename of a custom configuration profile or a
        %  structure representing a configuration profile.
        % 
        % Input Arguments:
        %  - obj (NwbFile) - An instance of the NwbFile class.
        % 
        %  - settingsReference (string | struct) - 
        %   The filename of a custom configuration profile or an in-memory
        %   structure representing a configuration profile.
        %
        % Name-Value Arguments:
        %  - OverrideExisting (logical) - 
        %   This boolean determines if existing DataPipe objects in the
        %   file will be reconfigured with the provided options. Default is
        %   false. **Important**: This does not work for DataPipes that has
        %   previously been exported to file.
        % 
        % Output Arguments:
        %  - datasetConfig - 
        %   (Optional) The configuration settings applied to the dataset.
        %
        % See also:
        %   io.config.enum.ConfigurationProfile
        %   NwbFile.applyDatasetSettingsProfile

            arguments
                obj (1,1) NwbFile
                settingsReference = []
                options.OverrideExisting (1,1) logical = false
            end

            datasetConfig = io.config.resolveDatasetConfiguration(settingsReference);

            nvPairs = namedargs2cell(options);
            io.config.applyDatasetConfiguration(obj, datasetConfig, nvPairs{:});
            if ~nargout
                clear datasetConfig
            end
        end

        function o = resolve(obj, path)
            if ischar(path)
                path = {path};
            end
            o = cell(size(path));
            for i = 1:numel(path)
                o{i} = io.resolvePath(obj, path{i});
            end
            if isscalar(o)
                o = o{1};
            end
        end

        function objectMap = searchFor(obj, typename, varargin)
            % searchFor - Search for for a given typename within the NwbFile object
            %
            % Including the full namespace is optional.
            %
            % .. warning:: 
            %   The returned paths are resolvable but do not necessarily
            %   indicate a real HDF5 path. Their only function is to be resolvable.

            objectMap = searchProperties(...
                containers.Map,...
                obj,...
                '',...
                typename,...
                varargin{:});
        end
        
        function nwbObjects = getTypeObjects(obj, typeName, options)
        % GETTYPEOBJECTS - Retrieve NWB objects of a specified type.
        % 
        % Syntax:
        %   nwbObjects = GETTYPEOBJECTS(obj, typeName) Retrieves NWB 
        %   objects of the specified type from the NwbFile object.
        % 
        %   nwbObjects = GETTYPEOBJECTS(obj, typeName, Name, Value) Retrieves NWB 
        %   objects of the specified type from the NwbFile object using provided
        %   name-value pairs controlling options.
        %
        % Input Arguments:
        %  - obj (NwbFile) - 
        %    The NwbFile object from which to retrieve NWB objects.
        %   
        %  - typeName (1,1) string - 
        %    The name of the type to search for. Can include namespace, but 
        %    does not have to, i.e types.core.TimeSeries and TimeSeries are
        %    supported.
        %   
        %  - options (name-value pairs) -
        %    Optional name-value pairs. Available options:
        %       
        %    - IncludeSubTypes logical - 
        %      Optional: set to true to include subclasses in the search. 
        %      Default is false.
        % 
        % Output Arguments:
        %   - nwbObjects (cell) -  
        %     A cell array of NWB objects of the specified type.
        %
        % Usage:
        %  Example 1 - Get all ElectricalSeries objects from NwbFile::
        %
        %    evalc('run("ecephys.mlx")');
        %    nwb.getTypeObjects('ElectricalSeries')
        %
        %  Example 2 - Get all ElectricalSeries and subtype objects from NwbFile::
        %
        %    evalc('run("ecephys.mlx")')
        %    nwb.getTypeObjects('ElectricalSeries', 'IncludeSubTypes', true)
        
            arguments
                obj
                typeName (1,1) string
                options.IncludeSubTypes (1,1) logical = false
            end
            flags = {};
            if options.IncludeSubTypes
                flags{end+1} = 'includeSubClasses';
            end

            objectMap = searchProperties(...
                containers.Map,...
                obj,...
                '',...
                char(typeName),...
                flags{:}, 'exactTypeMatch');
        
            % Filter to return exact types.
            nwbObjects = objectMap.values;
        end

        function nwbTypeNames = listNwbTypes(obj, options)
        % listNwbTypes - List all unique NWB (neurodata) types in file
            arguments
                obj (1,1) NwbFile
                options.IncludeParentTypes (1,1) logical = false
                options.IncludeNwbFile (1,1) logical = false
            end

            objectMap = searchProperties(containers.Map, obj, '', '');

            objects = objectMap.values();
            objectClassNames = cellfun(@(c) string(class(c)), objects);
            objectClassNames = unique(objectClassNames);

            keep = startsWith(objectClassNames, "types.");
            ignore = startsWith(objectClassNames, "types.untyped");

            nwbTypeNames = objectClassNames(keep & ~ignore);

            if options.IncludeNwbFile
                % Include class name for NWBFile superclass
                allSuperclasses = string(superclasses(obj));
                nwbTypeNames = [...
                    allSuperclasses(endsWith(allSuperclasses, 'NWBFile')), ...
                    nwbTypeNames];
            end

            if options.IncludeParentTypes
                includedNwbTypesWithParents = string.empty;
                for i = 1:numel(nwbTypeNames)
                    typeHierarchy = schemes.utility.listNwbTypeHierarchy(nwbTypeNames{i});
                    includedNwbTypesWithParents = [includedNwbTypesWithParents, typeHierarchy]; %#ok<AGROW>
                end
                nwbTypeNames = includedNwbTypesWithParents;
            end
        end
    end

    methods (Hidden)
        function resolveSoftLinks(obj)
            % Note: Will not find/resolve soft links that are nested within dynamic tables
            softLinkMap = obj.searchFor('types.untyped.SoftLink');
            softLinks = softLinkMap.values;
            for i = 1:numel(softLinks)
                for j = 1:numel(softLinks{i}) % each SoftLink can be a list
                    softLinks{i}(j).deref(obj);
                end
            end
        end
    end

    %% PRIVATE
    methods(Access=private)
        function addWasGeneratedBy(obj)
            if isprop(obj, 'general_was_generated_by')
                if isa(obj.general_was_generated_by, 'types.untyped.DataStub')
                    obj.general_was_generated_by = obj.general_was_generated_by.load();
                end
    
                matnwbInfo = ver('matnwb');
                wasGeneratedBy = {'matnwb'; matnwbInfo.Version};
    
                if isempty(obj.general_was_generated_by)
                    obj.general_was_generated_by = wasGeneratedBy;
                else
                    if ~any(contains(obj.general_was_generated_by(:), 'matnwb'))
                        obj.general_was_generated_by(:, end+1) = wasGeneratedBy;
                    end
                end
            end
        end

        function embedSpecifications(obj, output_file_id)
            jsonSpecs = schemes.exportJson();

            if isempty(jsonSpecs)
                % Call generateCore to create cached namespaces
                generateCore(obj.nwb_version)
                jsonSpecs = schemes.exportJson();
            end

            % Resolve the name of all types and parent types that are
            % included in this file. This will be used to filter the specs
            % to embed, so that only specs with used neurodata types are
            % embedded.
            includedNeurodataTypes = obj.listNwbTypes(...
                "IncludeParentTypes", true, ...
                "IncludeNwbFile", true);

            % Get the namespace names
            namespaceNames = getNamespacesForDataTypes(includedNeurodataTypes);
            
            % In the specs, the hyphen (-) is used as a word separator, while in
            % matnwb the underscore (_) is used. Translate names here:
            allMatlabNamespaceNames = strrep({jsonSpecs.name}, '-', '_');
            [~, keepIdx] = intersect(allMatlabNamespaceNames, namespaceNames, 'stable');
            jsonSpecs = jsonSpecs(keepIdx);

            io.spec.writeEmbeddedSpecifications(...
                output_file_id, ...
                jsonSpecs);

            io.spec.validateEmbeddedSpecifications(...
                output_file_id, ...
                strrep(namespaceNames, '_', '-'))
        end
        
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

                errorMessage = sprintf(...
                    ['Object(s) could not be created:\n%s\n\nThe listed '...
                    'object(s) above contain an ObjectView, RegionView, or ' ...
                    'SoftLink object that has failed to resolve itself. '...
                    'Please check for any references that were not assigned ' ...
                    'to the root  NwbFile or if any of the above paths are ' ...
                    'incorrect.'], file.addSpaces(strjoin(references, newline), 4));

                assert( ...
                    all(resolved), ...
                    'NWB:NwbFile:UnresolvedReferences', ...
                    errorMessage ...
                    )

                references(resolved) = [];
            end
        end
    end
end

% Local functions
function pathToObjectMap = searchProperties(...
        pathToObjectMap,...
        obj,...
        basePath,...
        typename,...
        varargin)
    assert(all(iscellstr(varargin)),...
        'NWB:NwbFile:SearchProperties:InvalidVariableArguments',...
        'Optional keywords for searchFor must be char arrays.');
    shouldSearchSuperClasses = any(strcmpi(varargin, 'includeSubClasses'));
    exactTypeMatch = any(strcmpi(varargin, 'exactTypeMatch'));

    if isa(obj, 'types.untyped.MetaClass')
        propertyNames = properties(obj);
        getProperty = @(x, prop) x.(prop);
    elseif isa(obj, 'types.untyped.Set')
        propertyNames = obj.keys();
        getProperty = @(x, prop) x.get(prop);
    elseif isa(obj, 'types.untyped.Anon')
        propertyNames = {obj.name};
        getProperty = @(x, prop) x.value;
    else
        error('NWB:NwbFile:SearchProperties:InvalidType',...
            'Invalid object type passed %s', class(obj));
    end

    searchTypename = @(obj, typename) isMatchedType(class(obj), typename, 'ExactMatch', exactTypeMatch);
    if shouldSearchSuperClasses
        searchTypename = @(obj, typename) metaHasType(metaclass(obj), typename, 'ExactMatch', exactTypeMatch);
    end

    for i = 1:length(propertyNames)
        propName = propertyNames{i};
        propValue = getProperty(obj, propName);
        fullPath = [basePath '/' propName];
        if searchTypename(propValue, typename)
            pathToObjectMap(fullPath) = propValue;
        end

        if isa(propValue, 'types.untyped.GroupClass')...
                || isa(propValue, 'types.untyped.Set')...
                || isa(propValue, 'types.untyped.Anon')
            % recursible (even if there is a match!)
            searchProperties(pathToObjectMap, propValue, fullPath, typename, varargin{:});
        end
    end
end

function tf = metaHasType(mc, typeSuffix, options)
    arguments
        mc meta.class
        typeSuffix (1,1) string
        options.ExactMatch (1,1) logical = false
    end

    tf = false;
    if isMatchedType(mc.Name, typeSuffix, 'ExactMatch', options.ExactMatch)
        tf = true;
        return;
    end

    for i = 1:length(mc.SuperclassList)
        sc = mc.SuperclassList(i);
        if metaHasType(sc, typeSuffix, 'ExactMatch', options.ExactMatch)
            tf = true;
            return;
        end
    end
end

function tf = isMatchedType(typeNameA, typeNameB, options)
    arguments
        typeNameA (1,1) string
        typeNameB (1,1) string
        options.ExactMatch (1,1) logical = false
    end

    if options.ExactMatch
        if contains(typeNameB, '.')
            % If namespace is provided, need to match on namespace and type.
            tf = strcmpi(typeNameA, typeNameB);
        else        
            tf = strcmpi(...
            extractTypeNameWithoutNamespace(typeNameA), ...
            extractTypeNameWithoutNamespace(typeNameB));
        end
    else
        tf = contains(typeNameA, typeNameB, 'IgnoreCase', true);
    end
end

function typeName = extractTypeNameWithoutNamespace(typeName)
    if contains(typeName, '.')
        splitName = split(typeName, '.');
        typeName = splitName{end};
    end
end

function namespaceNames = getNamespacesForDataTypes(nwbTypeNames)
% getNamespacesOfTypes - Get namespace names for a list of nwb types
    arguments
        nwbTypeNames (1,:) string
    end

    namespaceNames = repmat("", size(nwbTypeNames));
    pattern = '[types.]+\.(\w+)\.';

    for i = 1:numel(nwbTypeNames)
        namespaceNames(i) = regexp(nwbTypeNames(i), pattern, 'tokens', 'once');
    end
    namespaceNames = unique(namespaceNames);
end
