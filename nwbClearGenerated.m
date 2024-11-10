function clearedNamespaceNames = nwbClearGenerated(targetFolder, options)
    %% NWBCLEARGENERATED clears generated class files.
    arguments
        targetFolder (1,1) string  {mustBeFolder} = misc.getMatnwbDir()
        options.ClearCache (1,1) logical = false
    end
    typesPath = fullfile(targetFolder, '+types');
    listing = dir(typesPath);
    moduleNames = setdiff({listing.name}, {'+untyped', '+util', '.', '..'});
    generatedPaths = fullfile(typesPath, moduleNames);
    for i=1:length(generatedPaths)
        rmdir(generatedPaths{i}, 's');
    end

    if options.ClearCache
        cachePath = fullfile(targetFolder, 'namespaces');
        listing = dir(fullfile(cachePath, '*.mat'));
        generatedPaths = fullfile(cachePath, {listing.name});
        for i=1:length(generatedPaths)
            delete(generatedPaths{i});
        end
    end

    if nargout == 1 % Return names of cleared namespaces
        [~, clearedNamespaceNames] = fileparts(generatedPaths);
        clearedNamespaceNames = strrep(clearedNamespaceNames, '+', '');
        clearedNamespaceNames = string(clearedNamespaceNames);
    end
end