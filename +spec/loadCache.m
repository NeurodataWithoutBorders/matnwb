function Cache = loadCache(namespaceName, options)
%LOADCACHE Loads Raw Namespace Metadata from cached directory

arguments (Repeating)
    namespaceName (1,1) string
end
arguments
    options.savedir (1,1) string = misc.getMatnwbDir()
end

Cache = struct.empty; % Initialize output

namespaceList = string(namespaceName);

% Get the actual location of the matnwb directory.
namespaceDir = fullfile(options.savedir, 'namespaces');

fileList = dir(namespaceDir);
fileList = fileList(~[fileList.isdir]);
if ~isempty(namespaceList)
    names = {fileList.name};
    whitelistIdx = ismember(names, strcat(namespaceList + ".mat"));
    fileList = fileList(whitelistIdx);
end

if ~isempty(fileList)
    matPath = fullfile(namespaceDir, fileList(1).name);
    Cache = load(matPath); % initialize Cache first
    for iMat = 2:length(fileList)
        matPath = fullfile(namespaceDir, fileList(iMat).name);
        Cache(iMat) = load(matPath);
    end
end
end
