function Cache = loadCache(varargin)
%LOADCACHE Loads Raw Namespace Metadata from cached directory

saveDirMask = strcmp(varargin, 'savedir');
if any(saveDirMask)
    assert(~saveDirMask(end),...
        'NWB:LoadCache:InvalidParameter',...
        'savedir must be paired with the desired save directory.');
    saveDir = varargin{find(saveDirMask, 1, 'last') + 1};
    saveDirParametersMask = saveDirMask | circshift(saveDirMask, 1);
    namespaceList = varargin(~saveDirParametersMask);
else
    saveDir = misc.getMatnwbDir();
    namespaceList = varargin;
end

% Get the actual location of the matnwb directory.
namespaceDir = fullfile(saveDir, 'namespaces');

fileList = dir(namespaceDir);
fileList = fileList(~[fileList.isdir]);
if nargin > 0
    assert(iscellstr(namespaceList), 'Input arguments must be a list of namespace names.');
    names = {fileList.name};
    whitelistIdx = ismember(names, strcat(namespaceList, '.mat'));
    fileList = fileList(whitelistIdx);
end

if isempty(fileList)
    Cache = struct([]);
    return;
end

matPath = fullfile(namespaceDir, fileList(1).name);
Cache = load(matPath); % initialize Cache first
for iMat = 2:length(fileList)
    matPath = fullfile(namespaceDir, fileList(iMat).name);
    Cache(iMat) = load(matPath);
end
end