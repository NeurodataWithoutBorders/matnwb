function Cache = loadCache(varargin)
%LOADCACHE Loads Raw Namespace Metadata from cached directory

% Get the actual location of the matnwb directory.
fnLoc = dbstack('-completenames');
fnLoc = fnLoc(1).file;
[fnDir,~,~] = fileparts(fnLoc);
[fnDir,~,~] = fileparts(fnDir);

% Get full path name to namespaces directory
namespaceDir = fullfile(fnDir, 'namespaces');
% namespaceDir = 'namespaces';
fileList = dir(namespaceDir);
fileList = fileList(~[fileList.isdir]);
if nargin > 0
    assert(iscellstr(varargin), 'Input arguments must be a list of namespace names.');
    names = {fileList.name};
    fileNames = strrep(strcat(varargin, '.mat'), '-', '_');
    whitelistIdx = ismember(names, fileNames);
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