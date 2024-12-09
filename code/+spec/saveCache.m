function saveCache(NamespaceInfo, saveDir)
%SAVECACHE saves namespace info as .mat in `namespaces` directory

namespacePath = fullfile(saveDir, 'namespaces');
if ~isfolder(namespacePath)
    mkdir(namespacePath);
end

cachePath = fullfile(namespacePath, [NamespaceInfo.name '.mat']);
save(cachePath, '-struct', 'NamespaceInfo');
end

