function saveCache(NamespaceInfo, varargin)
%SAVECACHE saves namespace info as .mat in `namespaces` directory

p = inputParser;
addParameter(p, 'savedir', misc.getMatnwbDir(),...
    @(s)validateattributes(s, {'char', 'string'}, {'scalartext'}));
parse(p, varargin{:});

saveDir = p.Results.savedir;

namespacePath = fullfile(saveDir, 'namespaces');
if 7 ~= exist(namespacePath, 'dir')
    mkdir(namespacePath);
end

cachePath = fullfile(namespacePath, [NamespaceInfo.name '.mat']);
save(cachePath, '-struct', 'NamespaceInfo');
end

