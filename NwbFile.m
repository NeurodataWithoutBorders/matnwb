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
        function obj = NwbFile(propValues)
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
        % export - Export NWB file object

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

            %equate reference time to session_start_time if empty
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
            % Searches this NwbFile object for a given typename
            % Including the full namespace is optional.
            % WARNING: The returned paths are resolvable but do not necessarily
            % indicate a real HDF5 path. Their only function is to be resolvable.
            objectMap = searchProperties(...
                containers.Map,...
                obj,...
                '',...
                typename,...
                varargin{:});
        end

        function nwbTypeNames = listNwbTypes(obj)
        % listNwbTypes - List all unique NWB types in file
            objectMap = searchProperties(containers.Map, obj, '', '');

            objects = objectMap.values();
            objectClassNames = cellfun(@(c) string(class(c)), objects);
            objectClassNames = unique(objectClassNames);

            keep = startsWith(objectClassNames, "types.");
            ignore = startsWith(objectClassNames, "types.untyped");

            nwbTypeNames = objectClassNames(keep & ~ignore);
        end
    end

    %% PRIVATE
    methods(Access=private)
        function embedSpecifications(obj, output_file_id)
            jsonSpecs = schemes.exportJson();

            % Resolve the name of all types and parent types that are
            % included in this file, in order to only include the specs for
            % namespaces of types that are included in the file.
            includedNwbTypes = obj.listNwbTypes();
            includedNwbTypesWithParents = string.empty;
            for i = 1:numel(includedNwbTypes)
                typeHierarchy = schemes.utility.listNwbTypeHierarchy(includedNwbTypes{i});
                includedNwbTypesWithParents = [includedNwbTypesWithParents, typeHierarchy]; %#ok<AGROW>
            end
            
            % Get the namespace names
            namespaceNames = getNamespacesOfTypes(includedNwbTypes);
            
            % In the specs, the hyphen (-) is used as a word separator, while in
            % matnwb the underscore (_) is used. Translate names here:
            allMatlabNamespaceNames = strrep({jsonSpecs.name}, '-', '_');
            [~, keepIdx] = intersect(allMatlabNamespaceNames, namespaceNames, 'stable');
            jsonSpecs = jsonSpecs(keepIdx);

            io.spec.writeEmbeddedSpecifications(output_file_id, jsonSpecs);
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

function tf = metaHasType(mc, typeSuffix)
    assert(isa(mc, 'meta.class'));
    tf = false;
    if contains(mc.Name, typeSuffix, 'IgnoreCase', true)
        tf = true;
        return;
    end

    for i = 1:length(mc.SuperclassList)
        sc = mc.SuperclassList(i);
        if metaHasType(sc, typeSuffix)
            tf = true;
            return;
        end
    end
end

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

    searchTypename = @(obj, typename) contains(class(obj), typename, 'IgnoreCase', true);
    if shouldSearchSuperClasses
        searchTypename = @(obj, typename) metaHasType(metaclass(obj), typename);
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

function namespaceNames = getNamespacesOfTypes(nwbTypeNames)
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
