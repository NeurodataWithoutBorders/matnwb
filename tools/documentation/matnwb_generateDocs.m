function matnwb_generateDocs()
% MATNWB_GENERATEDOCS generates html docs for MatNWB API functions
%
%   matnwb_generateDocs() generates html documentation for MATLAB files in the 
%   current matnwb root directory.
%
%   The following files are included:
%       - generateCore.m
%       - generateExtension.m
%       - nwbRead.m
%       - nwbExport.m
%
%   Requires <a href="matlab:web('https://github.com/gllmflndn/m2html')">m2html</a> in your path.

rootDir = misc.getMatnwbDir();
rootFiles = dir(rootDir);
rootFiles = {rootFiles.name};
rootWhitelist = {'generateCore.m', 'generateExtension.m', 'nwbRead.m', 'nwbExport.m'};
isWhitelisted = ismember(rootFiles, rootWhitelist);
rootFiles(~isWhitelisted) = [];

docDir = fullfile(rootDir, 'doc');
m2html('mfiles', rootFiles, 'htmldir', docDir);

% correct html files in root directory as the stylesheets will be broken
fprintf('Correcting files in root directory...\n');
rootFiles = dir(docDir);
rootFiles = {rootFiles.name};
htmlMatches = regexp(rootFiles, '\.html$', 'once');
isHtmlFile = ~cellfun('isempty', htmlMatches);
rootFiles(~isHtmlFile) = [];
rootFiles = fullfile(docDir, rootFiles);

for iDoc=1:length(rootFiles)
    fileName = rootFiles{iDoc};
    fprintf('Processing %s...\n', fileName);
    fileReplace(fileName, '\.\.\/', '');
end

% correct index.html so the header indicates MatNWB
fprintf('Correcting index.html Header...\n');
indexPath = fullfile(docDir, 'index.html');
fileReplace(indexPath, 'Index for \.', 'Index for MatNWB');

% remove directories listing in index.html
fprintf('Removing index.html directories listing...\n');
matchPattern = ['<h2>Subsequent directories:</h2>\r?\n'...
    '<ul style="list-style-image:url\(matlabicon\.gif\)">\r?\n'...
    '(:?<li>.+</li>)+</ul>'];
fileReplace(indexPath, matchPattern, '');
end

function fileReplace(fileName, regexPattern, replacement)
file = fopen(fileName, 'r');
fileText = fread(file, '*char') .';
fclose(file);
fileText = regexprep(fileText, regexPattern, replacement);
file = fopen(fileName, 'W');
fwrite(file, fileText);
fclose(file);
end