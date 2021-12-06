function saveCache(NamespaceInfo, saveDir)
%SAVECACHE saves namespace info as .mat in `namespaces` directory

namespacePath = fullfile(saveDir, 'namespaces');
if 7 ~= exist(namespacePath, 'dir')
    mkdir(namespacePath);
end

cachePath = fullfile(namespacePath, [NamespaceInfo.name '.mat']);
save(cachePath, '-struct', 'NamespaceInfo');
end

