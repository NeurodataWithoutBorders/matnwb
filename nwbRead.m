function nwb = nwbRead(filename, varargin)
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

assert(iscellstr(varargin), 'NWB:NWBRead:InvalidParameters',...
    'Optional parameters must all be character arrays.'); %#ok<ISCLSTR>

ignoreCache = any(strcmpi(varargin, 'ignorecache'));

saveDirMask = strcmpi(varargin, 'savedir');
assert(isempty(saveDirMask) || ~saveDirMask(end), 'NWB:NWBRead:InvalidSaveDir',...
    '`savedir` is a key value pair requiring a directory string as a value.');
if any(saveDirMask)
    saveDir = varargin{find(saveDirMask, 1, 'last') + 1};
else
    saveDir = misc.getMatnwbDir();
end

Blacklist = struct(...
    'attributes', {{'.specloc', 'object_id'}},...
    'groups', {{}});
validateattributes(filename, {'char', 'string'}, {'scalartext', 'nonempty'});

specLocation = getEmbeddedSpec(filename);
if ~isempty(specLocation)
    Blacklist.groups{end+1} = specLocation;
end

if ~ignoreCache
    if isempty(specLocation)
        try
            generateCore(util.getSchemaVersion(filename), 'savedir', saveDir);
        catch ME
            if ~strcmp(ME.identifier, 'NWB:GenerateCore:MissingCoreSchema')
                rethrow(ME);
            end
        end
    else
        generateSpec(filename, h5info(filename, specLocation), 'savedir', saveDir);
    end
    rehash();
end

nwb = io.parseGroup(filename, h5info(filename), Blacklist);
end

function specLocation = getEmbeddedSpec(filename)
specLocation = '';
fid = H5F.open(filename);
try
    %check for .specloc
    attributeId = H5A.open(fid, '.specloc');
    referenceRawData = H5A.read(attributeId);
    specLocation = H5R.get_name(attributeId, 'H5R_OBJECT', referenceRawData);
    H5A.close(attributeId);
catch ME
    if ~strcmp(ME.identifier, 'MATLAB:imagesci:hdf5lib:libraryError')
        rethrow(ME);
    end % don't error if the attribute doesn't exist.
end

H5F.close(fid);
end

function generateSpec(filename, specinfo, varargin)
saveDirMask = strcmp(varargin, 'savedir');
if any(saveDirMask)
    assert(~saveDirMask(end),...
        'NWB:Read:InvalidParameter',...
        'savedir must be paired with the desired save directory.');
    saveDir = varargin{find(saveDirMask, 1, 'last') + 1};
else
    saveDir = misc.getMatnwbDir();
end

specNames = cell(size(specinfo.Groups));
fid = H5F.open(filename);
for iGroup = 1:length(specinfo.Groups)
    location = specinfo.Groups(iGroup).Groups(1);
    
    namespaceName = split(specinfo.Groups(iGroup).Name, '/');
    namespaceName = namespaceName{end};
    
    filenames = {location.Datasets.Name};
    if ~any(strcmp('namespace', filenames))
        warning('NWB:Read:GenerateSpec:CacheInvalid',...
        'Couldn''t find a `namespace` in namespace `%s`.  Skipping cache generation.',...
        namespaceName);
        return;
    end
    sourceNames = {location.Datasets.Name};
    fileLocation = strcat(location.Name, '/', sourceNames);
    schemaMap = containers.Map;
    for iFileLocation = 1:length(fileLocation)
        did = H5D.open(fid, fileLocation{iFileLocation});
        if strcmp('namespace', sourceNames{iFileLocation})
            namespaceText = H5D.read(did);
        else
            schemaMap(sourceNames{iFileLocation}) = H5D.read(did);    
        end
        H5D.close(did);
    end
    
    Namespaces = spec.generate(namespaceText, schemaMap);
    % Handle embedded namespaces.
    Namespace = Namespaces(strcmp({Namespaces.name}, namespaceName));
    
    spec.saveCache(Namespace, saveDir);
    specNames{iGroup} = Namespace.name;
end
H5F.close(fid);

missingNames = cell(size(specNames));
for iName = 1:length(specNames)
    name = specNames{iName};
    try
        file.writeNamespace(name, saveDir);
    catch ME
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
