function nwb = nwbRead(filename, flags, options)
    %NWBREAD Reads an NWB file.
    %  nwb = NWBREAD(filename) Reads the nwb file at filename and returns an
    %  NWBFile object representing its contents.
    %  nwb = nwbRead(filename, 'ignorecache') Reads the nwb file without generating classes
    %  off of the cached schema if one exists.
    %
    %  nwb = NWBREAD(filename, options)
    %
    %  Requires that core and extension NWB types have been generated
    %  and reside in a 'types' package on the matlab path.
    %
    %  Example:
    %    nwb = nwbRead('data.nwb');
    %    nwb = nwbRead('data.nwb', 'ignorecache');
    %    nwb = nwbRead('data.nwb', 'savedir', '.');
    %
    %  See also GENERATECORE, GENERATEEXTENSION, NWBFILE, NWBEXPORT
    
    arguments
        filename (1,1) string {matnwb.common.mustBeNwbFile}
    end
    arguments (Repeating)
        flags (1,1) string {mustBeMember(flags, "ignorecache")}
    end
    arguments
        options.savedir (1,1) string = misc.getMatnwbDir(); % {mustBeFolder} ?
    end

    regenerateSchemaClasses = not( any(strcmpi(string(flags), 'ignorecache')) );

    schemaVersion = util.getSchemaVersion(filename);
    try
        matnwb.common.mustBeValidSchemaVersion(schemaVersion)
    catch
        warning('NWB:Read:UnsupportedSchema', ...
            ['NWB schema version `%s` is not support by this version of MatNWB. ' ...
            'This file is not guaranteed to be supported.'], schemaVersion )
    end

    specLocation = io.spec.getEmbeddedSpecLocation(filename);

    if regenerateSchemaClasses
        if isempty(specLocation)
            try
                generateCore(schemaVersion, 'savedir', options.savedir);
            catch ME
                if ~strcmp(ME.identifier, 'NWB:VersionValidator:UnsupportedSchemaVersion')
                    rethrow(ME);
                end
            end
        else
            generateEmbeddedSpec(filename, specLocation, 'savedir', options.savedir);
        end
        rehash();
    end

    blackList = struct(...
        'attributes', {{'.specloc', 'object_id'}},...
        'groups', {{}});    
    if ~isempty(specLocation)
        blackList.groups{end+1} = specLocation;
    end
    
    nwb = io.parseGroup(filename, h5info(filename), blackList);
end


function generateEmbeddedSpec(filename, specLocation, options)
% generateEmbeddedSpec - Generate embedded specifications / namespaces
    arguments
        filename (1,1) string {mustBeFile}
        specLocation (1,1) string
        options.savedir (1,1) string = misc.getMatnwbDir(); % {mustBeFolder} ?
    end

    specs = io.spec.readEmbeddedSpecifications(filename, specLocation);
    specNames = cell(size(specs));

    for iSpec = 1:numel(specs)
        namespaceName = specs{iSpec}.namespaceName;
        namespaceDef = specs{iSpec}.namespaceText;
        schemaMap = specs{iSpec}.schemaMap;

        parsedNamespace = spec.generate(namespaceDef, schemaMap);
        
        % Ensure the namespace name matches the name of the parsed namespace
        isMatch = strcmp({parsedNamespace.name}, namespaceName);
        if ~any(isMatch) % Legacy check
            % Check if namespaceName is using the old underscore convention.
            isMatch = strcmp({parsedNamespace.name}, strrep(namespaceName, '_', '-'));
        end

        assert(any(isMatch), ...
            'NWB:Namespace:NameNotFound', ...
            'Namespace `%s` not found in specification. Perhaps an extension should be generated?', ...
            namespaceName);

        parsedNamespace = parsedNamespace(isMatch);
        
        spec.saveCache(parsedNamespace, options.savedir);
        specNames{iSpec} = parsedNamespace.name;
    end
    
    missingNames = cell(size(specNames));
    for iName = 1:length(specNames)
        name = specNames{iName};
        try
            file.writeNamespace(name, options.savedir);
        catch ME
            % Todo: Can this actually happen?
            if strcmp(ME.identifier, 'NWB:Namespace:CacheMissing')
                missingNames{iName} = name;
            else
                rethrow(ME);
            end
        end
    end

    missingNames(cellfun('isempty', missingNames)) = [];
    assert(isempty(missingNames), 'NWB:Namespace:DependencyMissing',...
        'Missing generated caches and dependent caches for the following namespaces:\n%s',...
        misc.cellPrettyPrint(missingNames));
end
