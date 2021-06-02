function saveCache(NamespaceInfo)
%SAVECACHE saves namespace info as .mat in `namespaces` directory
namespacePath = misc.getNamespaceDir();
if isempty(namespacePath)
    namespacePath = fullfile(pwd, 'namespaces');
    mkdir(namespacePath);
end
cachePath = fullfile(namespacePath, [NamespaceInfo.name '.mat']);
save(cachePath, '-struct', 'NamespaceInfo');
end

