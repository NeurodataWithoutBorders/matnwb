function nwbClearGenerated()
    %% NWBCLEARGENERATED clears generated class files.
    nwbDir = misc.getMatnwbDir();
    typesPath = fullfile(nwbDir, '+types');
    listing = dir(typesPath);
    moduleNames = setdiff({listing.name}, {'+untyped', '+util', '.', '..'});
    generatedPaths = fullfile(typesPath, moduleNames);
    for i=1:length(generatedPaths)
        rmdir(generatedPaths{i}, 's');
    end
end