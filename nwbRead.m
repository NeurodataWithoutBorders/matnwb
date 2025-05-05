function nwb = nwbRead(filename, flags, options)
% NWBREAD - Read an NWB file.
%
% Syntax:
%  nwb = NWBREAD(filename) Reads the nwb file at filename and returns an
%  NWBFile object representing its contents.
%
%  nwb = NWBREAD(filename, flags) Reads the nwb file using optional
%  flags controlling the mode for how to read the file. See input
%  arguments for a list of available flags.
%
%  nwb = NWBREAD(filename, Name, Value) Reads the nwb file using optional
%  name-value pairs controlling options for how to read the file.
%
% Input Arguments:
%  - filename (string) -
%    Filepath pointing to an NWB file.
%
%  - flags (string) -
%    Flag for setting the mode for the NWBREAD operation. Available options are:
%    'ignorecache'. If the 'ignorecache' flag is used, classes for NWB data
%    types are not re-generated based on the embedded schemas in the file.
%
%  - options (name-value pairs) -
%    Optional name-value pairs. Available options:
%
%    - savedir (string) -
%      A folder to save generated classes for NWB types.
%
% Output Arguments:
%  - nwb (NwbFile) - Nwb file object
%
% Usage:
%  Example 1 - Read an NWB file::
%
%    nwb = nwbRead('data.nwb');
%
%  Example 2 - Read an NWB file without re-generating classes for NWB types::
%
%    nwb = nwbRead('data.nwb', 'ignorecache');
%
%  Note: This is a good option to use if you are reading several files
%  which are created of the same version of the NWB schemas.
%
%  Example 3 - Read an NWB file and generate classes for NWB types in the current working directory::
%
%    nwb = nwbRead('data.nwb', 'savedir', '.');
%
% See also:
%   generateCore, generateExtension, NwbFile, nwbExport
    
    arguments
        filename (1,1) string {matnwb.common.mustBeNwbFile}
    end
    arguments (Repeating)
        flags (1,1) string {mustBeMember(flags, "ignorecache")}
    end
    arguments
        options.savedir (1,1) string = misc.getMatnwbDir(); % {matnwb.common.compatibility.mustBeFolder} ?
    end

    shouldRegenerateSchemaClasses = not( any(strcmpi(string(flags), 'ignorecache')) );

    schemaVersionActive = matnwb.common.getActiveSchemaVersion();
    schemaVersionOfFile = util.getSchemaVersion(filename);
    isSchemaVersionMismatch = ~strcmp(schemaVersionOfFile, schemaVersionActive);

    if isSchemaVersionMismatch
        warnIfUnsupportedSchemaVersion(schemaVersionOfFile)
    end

    specLocation = io.spec.getEmbeddedSpecLocation(filename);
    if shouldRegenerateSchemaClasses
        if isempty(specLocation) % No embedded specifications
            try
                generateCore(schemaVersionOfFile, 'savedir', options.savedir);
            catch ME
                if ~strcmp(ME.identifier, 'NWB:VersionValidator:UnsupportedSchemaVersion')
                    rethrow(ME);
                end
            end
        else
            generateEmbeddedSpec(filename, specLocation, 'savedir', options.savedir);
        end
    else
        warnIfSchemaVersionsMismatch(schemaVersionOfFile, schemaVersionActive)
    end

    blackList = struct(...
        'attributes', {{'.specloc', 'object_id'}},...
        'groups', {{}});
    if ~isempty(specLocation)
        blackList.groups{end+1} = specLocation;
    end
    
    try
        nwb = io.parseGroup(filename, h5info(filename), blackList);
    catch ME
        if isSchemaVersionMismatch ...
                && strcmp(ME.identifier, 'MATLAB:class:RequireSuperClass')
            throwExceptionWithCauseOnVersionMismatch(ME)
        else
            rethrow(ME)
        end
    end
end

function generateEmbeddedSpec(filename, specLocation, options)
% generateEmbeddedSpec - Generate embedded specifications / namespaces
    arguments
        filename (1,1) string {matnwb.common.compatibility.mustBeFile}
        specLocation (1,1) string
        options.savedir (1,1) string = misc.getMatnwbDir(); % {matnwb.common.compatibility.mustBeFolder} ?
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
    rehash()

    missingNames(cellfun('isempty', missingNames)) = [];
    assert(isempty(missingNames), 'NWB:Namespace:DependencyMissing',...
        'Missing generated caches and dependent caches for the following namespaces:\n%s',...
        misc.cellPrettyPrint(missingNames));
end

function warnIfUnsupportedSchemaVersion(schemaVersionOfFile)
    try
        matnwb.common.mustBeValidSchemaVersion(schemaVersionOfFile)
    catch
        warning('NWB:Read:UnsupportedSchemaVersion', ...
            ['The NWB schema version `%s` used to create this file is not ' ...
            'supported by the current version of MatNWB. The file may not be ' ...
            'read correctly.'], ...
            schemaVersionOfFile )
    end
end

function warnIfSchemaVersionsMismatch(schemaVersionOfFile, schemaVersionCurrent)
    if ~strcmp(schemaVersionCurrent, schemaVersionOfFile)
        warning('NWB:Read:AttemptReadWithVersionMismatch', ...
            ['The NWB version used to generate the file (%s) is different ', ...
            'than current NWB version (%s). Some elements of the file might ', ...
            'not be read correctly. Maybe you did not mean to use nwbRead ', ...
            'with the "ignorecache" flag.'], ...
            schemaVersionOfFile, schemaVersionCurrent)
    end
end

function throwExceptionWithCauseOnVersionMismatch(ME)
    MECause = MException(...
        'NWB:Read:VersionConflict', ...
        ['This error typically occurs if NWB objects created with a ', ...
        'different version are still loaded in memory. Try using ', ...
        '`clear all` and run `nwbRead` again.']);
    ME = ME.addCause(MECause);
    throwAsCaller(ME)
end
