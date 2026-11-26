function generateNamespaces(namespaceInfoList, saveDir)
% generateNamespaces - Generate classes for namespaces, reusing cached classes.
%
%   matnwb.internal.typecache.generateNamespaces(namespaceInfoList, saveDir)
%   puts the classes for each parsed namespace in namespaceInfoList into
%   saveDir/+types and its specification into saveDir/namespaces.
%   namespaceInfoList is a struct array as returned by spec.generate.
%
%   Classes for a namespace are generated once and kept in the cache folder
%   (see matnwb.internal.typecache.getCacheFolder), in the subfolder
%   resources/<namespace>/<version>/<key>, where <key> is the start of the
%   cache key. Each entry holds a +types folder, and genpath skips folders
%   named "resources", so adding a folder that contains the cache with
%   addpath(genpath(...)) does not put the cached classes on the path.
%
%   Several entries can exist for one namespace version: the same version
%   can be generated from different specifications (the copy bundled with
%   matnwb and the copy embedded in a file by another writer), against
%   different dependencies, or by different versions of the generator. At
%   most three entries are kept per namespace version; writing a fourth
%   removes the one that was used least recently. When the cached classes were made from the
%   same specification, by the same generator and against the same
%   dependencies, they are copied into saveDir instead of being generated
%   again. Otherwise the classes are generated into saveDir and the cache
%   entry is replaced.
%
%   Namespaces are processed in dependency order. A dependency that is not
%   in namespaceInfoList must already have a specification in
%   saveDir/namespaces.

    arguments
        namespaceInfoList (1,:) struct
        saveDir (1,1) string
    end

    % Entries kept per namespace version. Enough for a few variants in use at
    % the same time, while bounding the growth of the cache.
    maxEntriesPerVersion = 3;
    % Characters of the cache key used as the entry folder name. The record
    % in the folder holds the full key, which a hit must match.
    entryKeyLength = 12;

    namespaceInfoList = sortByDependency(namespaceInfoList);
    generatorHash = matnwb.internal.typecache.computeGeneratorHash();
    cacheFolder = matnwb.internal.typecache.getCacheFolder();

    % Cache keys of the namespaces handled so far, used for their dependents.
    cacheKeys = containers.Map();

    for iNamespace = 1:numel(namespaceInfoList)
        namespaceInfo = namespaceInfoList(iNamespace);
        name = namespaceInfo.name;

        dependencyKeys = getDependencyKeys(namespaceInfo, cacheKeys, saveDir, generatorHash);
        specHash = matnwb.internal.typecache.computeSpecHash(namespaceInfo);
        cacheKey = composeCacheKey(specHash, generatorHash, dependencyKeys);
        cacheKeys(name) = cacheKey;

        versionFolder = fullfile(cacheFolder, "resources", name, namespaceInfo.version);
        entryFolder = fullfile(versionFolder, extractBefore(cacheKey, entryKeyLength + 1));
        if readCacheKey(entryFolder) == cacheKey
            copyFromCache(entryFolder, name, saveDir)
            markAsUsed(entryFolder)
        else
            generateIntoSaveDir(namespaceInfo, saveDir)
            record = struct( ...
                "Name", name, ...
                "Version", namespaceInfo.version, ...
                "CacheKey", cacheKey, ...
                "SpecHash", specHash, ...
                "GeneratorHash", generatorHash, ...
                "Dependencies", {namespaceInfo.dependencies});
            copyToCache(entryFolder, name, saveDir, record)
            markAsUsed(entryFolder)
            removeLeastRecentlyUsed(versionFolder, maxEntriesPerVersion)
        end
    end
    rehash()
end

function namespaceInfoList = sortByDependency(namespaceInfoList)
% sortByDependency - Order namespaces so that dependencies come first.
%
%   Only dependencies within namespaceInfoList affect the order.

    names = {namespaceInfoList.name};
    sortedIndices = zeros(1, 0);
    isPlaced = false(size(names));

    while ~all(isPlaced)
        placedThisRound = false;
        for iNamespace = find(~isPlaced)
            dependencies = namespaceInfoList(iNamespace).dependencies;
            unplacedNames = names(~isPlaced);
            if ~any(ismember(dependencies, unplacedNames))
                sortedIndices(end+1) = iNamespace; %#ok<AGROW>
                isPlaced(iNamespace) = true;
                placedThisRound = true;
            end
        end
        assert(placedThisRound, "NWB:TypeCache:CircularDependency", ...
            "The namespaces %s depend on each other in a cycle.", ...
            strjoin(names(~isPlaced), ", "))
    end
    namespaceInfoList = namespaceInfoList(sortedIndices);
end

function dependencyKeys = getDependencyKeys(namespaceInfo, cacheKeys, saveDir, generatorHash)
% getDependencyKeys - Get the cache key of each dependency of a namespace.
%
%   A dependency handled earlier in this call has its key in cacheKeys.
%   Otherwise its key is computed from its specification in saveDir.

    dependencyNames = string(namespaceInfo.dependencies);
    dependencyKeys = strings(size(dependencyNames));
    for iDependency = 1:numel(dependencyNames)
        dependencyName = dependencyNames(iDependency);
        if ~isKey(cacheKeys, dependencyName)
            dependencyInfo = spec.loadCache(dependencyName, "savedir", saveDir);
            assert(~isempty(dependencyInfo), "NWB:Namespace:DependencyMissing", ...
                "Namespace ""%s"" depends on ""%s"", which has not been generated. " + ...
                "Generate ""%s"" first, with generateCore or generateExtension.", ...
                namespaceInfo.name, dependencyName, dependencyName)
            dependencyKeys(iDependency) = ...
                computeSavedCacheKey(dependencyInfo, cacheKeys, saveDir, generatorHash);
        else
            dependencyKeys(iDependency) = cacheKeys(dependencyName);
        end
    end
end

function cacheKey = computeSavedCacheKey(namespaceInfo, cacheKeys, saveDir, generatorHash)
% computeSavedCacheKey - Compute the cache key of a namespace whose specification is in saveDir.

    dependencyKeys = getDependencyKeys(namespaceInfo, cacheKeys, saveDir, generatorHash);
    specHash = matnwb.internal.typecache.computeSpecHash(namespaceInfo);
    cacheKey = composeCacheKey(specHash, generatorHash, dependencyKeys);
    cacheKeys(namespaceInfo.name) = cacheKey; %#ok<NASGU> containers.Map is a handle
end

function cacheKey = composeCacheKey(specHash, generatorHash, dependencyKeys)
% composeCacheKey - Combine the hashes that determine the generated classes.
%
%   Generated classes copy information from the classes they extend, so the
%   key includes the keys of all dependencies, and through them the keys of
%   their dependencies.

    lines = ["spec:" + specHash, "generator:" + generatorHash, ...
        "dependency:" + sort(dependencyKeys(:))'];
    cacheKey = matnwb.internal.typecache.computeSha256(strjoin(lines, newline));
end

function cacheKey = readCacheKey(entryFolder)
% readCacheKey - Read the cache key of a cache entry, or "" if there is none.
%
%   The record file is written last, so an entry without one is incomplete.

    recordPath = fullfile(entryFolder, "record.json");
    if isfile(recordPath)
        record = jsondecode(fileread(recordPath));
        cacheKey = string(record.CacheKey);
    else
        cacheKey = "";
    end
end

function generateIntoSaveDir(namespaceInfo, saveDir)
% generateIntoSaveDir - Generate classes for a namespace into saveDir.

    % Remove classes of the version generated earlier, which the new version
    % may not define.
    removeFolderIfPresent(getTypesFolder(saveDir, namespaceInfo.name))

    spec.saveCache(namespaceInfo, saveDir);
    file.writeNamespace(namespaceInfo.name, saveDir);
end

function copyFromCache(entryFolder, name, saveDir)
% copyFromCache - Copy the classes and specification of a cache entry into saveDir.

    targetTypesFolder = getTypesFolder(saveDir, name);
    removeFolderIfPresent(targetTypesFolder)
    copyfile(getTypesFolder(entryFolder, name), targetTypesFolder)

    namespacesFolder = fullfile(saveDir, "namespaces");
    if ~isfolder(namespacesFolder)
        mkdir(namespacesFolder)
    end
    copyfile(fullfile(entryFolder, "namespace.mat"), fullfile(namespacesFolder, name + ".mat"))
end

function copyToCache(entryFolder, name, saveDir, record)
% copyToCache - Store the classes just generated in saveDir as a cache entry.
%
%   An existing folder for the entry is incomplete (readCacheKey found no
%   matching record), so it is replaced.

    removeFolderIfPresent(entryFolder)
    mkdir(entryFolder)
    copyfile(getTypesFolder(saveDir, name), getTypesFolder(entryFolder, name))
    copyfile(fullfile(saveDir, "namespaces", name + ".mat"), fullfile(entryFolder, "namespace.mat"))

    % Write the record last: its presence marks the entry as complete.
    fileId = fopen(fullfile(entryFolder, "record.json"), "w");
    fileCleanup = onCleanup(@() fclose(fileId));
    fwrite(fileId, jsonencode(record, "PrettyPrint", true), "char");
end

function markAsUsed(entryFolder)
% markAsUsed - Record the time an entry was last written or copied from.
%
%   The time is stored as text, because file modification times can have
%   a resolution of a second, which cannot order entries used in quick
%   succession.
    fileId = fopen(fullfile(entryFolder, "last-used.txt"), "w");
    fileCleanup = onCleanup(@() fclose(fileId));
    fprintf(fileId, "%.6f", posixtime(datetime("now")));
end

function removeLeastRecentlyUsed(versionFolder, maxEntryCount)
% removeLeastRecentlyUsed - Keep only the most recently used entries of a namespace version.
%
%   An entry without a time of last use, such as an incomplete one, counts
%   as the least recently used.
    listing = dir(versionFolder);
    listing = listing([listing.isdir] & ~ismember({listing.name}, {'.', '..'}));
    if numel(listing) <= maxEntryCount
        return
    end

    entryFolders = string(fullfile(versionFolder, {listing.name}));
    lastUsedTimes = zeros(size(entryFolders));
    for iEntry = 1:numel(entryFolders)
        lastUsedPath = fullfile(entryFolders(iEntry), "last-used.txt");
        if isfile(lastUsedPath)
            lastUsedTimes(iEntry) = str2double(fileread(lastUsedPath));
        end
    end
    [~, newestFirst] = sort(lastUsedTimes, "descend");
    for iEntry = newestFirst(maxEntryCount+1:end)
        rmdir(entryFolders(iEntry), "s")
    end
end

function typesFolder = getTypesFolder(rootFolder, namespaceName)
    typesFolder = fullfile(rootFolder, "+types", "+" + misc.str2validName(char(namespaceName)));
end

function removeFolderIfPresent(folderPath)
    if isfolder(folderPath)
        rmdir(folderPath, "s")
    end
end
