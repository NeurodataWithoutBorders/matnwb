function installExtension(extensionName)
% installExtension - Install NWB extension from Neurodata Extensions Catalog
%
%   matnwb.extension.nwbInstallExtension(extensionName) installs a Neurodata 
%   Without Borders (NWB) extension from the Neurodata Extensions Catalog to 
%   extend the functionality of the core NWB schemas. 

    arguments
        extensionName (1,1) string
    end

    repoTargetFolder = fullfile(userpath, "NWB-Extension-Source");
    if ~isfolder(repoTargetFolder); mkdir(repoTargetFolder); end

    T = matnwb.extension.listExtensions();
    isMatch = T.name == extensionName;

    extensionList = join( compose("  %s", [T.name]), newline );
    assert( ...
        any(isMatch), ...
        'NWB:InstallExtension:ExtensionNotFound', ...
        'Extension "%s" was not found in the extension catalog:\n', extensionList)
    
    defaultBranchNames = ["main", "master"];
    
    wasDownloaded = false;
    for i = 1:2
        try
            repositoryUrl = T{isMatch, 'src'};
            if endsWith(repositoryUrl, '/')
                repositoryUrl = extractBefore(repositoryUrl, strlength(repositoryUrl));
            end
            if contains(repositoryUrl, 'github.com')
                downloadUrl = sprintf( '%s/archive/refs/heads/%s.zip', repositoryUrl, defaultBranchNames(i) );
            
            elseif contains(repositoryUrl, 'gitlab.com')
                repoPathSegments = strsplit(repositoryUrl, '/');
                repoName = repoPathSegments{end};
                downloadUrl = sprintf( '%s/-/archive/%s/%s-%s.zip', ...
                    repositoryUrl, defaultBranchNames(i), repoName, defaultBranchNames(i));
            else
                error('NWB:InstallExtension:UnknownRepository', ...
                    'Extension "%s" is located in an unsupported repository / source location. Please create an issue on matnwb''s github page', extensionName)
            end
            repoTargetFolder = downloadZippedRepo(downloadUrl, repoTargetFolder, true, true);
            wasDownloaded = true;
            break
        catch ME
            if strcmp(ME.identifier, 'MATLAB:webservices:HTTP404StatusCodeError')
                continue
            else
                rethrow(ME)
            end
        end
    end
    if ~wasDownloaded
        error('NWB:InstallExtension:DownloadFailed', ...
            'Failed to download spec for extension "%s"', extensionName)
    end
    L = dir(fullfile(repoTargetFolder, 'spec', '*namespace.yaml'));
    assert(...
        ~isempty(L), ...
        'NWB:InstallExtension:NamespaceNotFound', ...
        'No namespace file was found for extension "%s"', extensionName ...
        )
    assert(...
        numel(L)==1, ...
        'NWB:InstallExtension:MultipleNamespacesFound', ...
        'More than one namespace file was found for extension "%s"', extensionName ...
        )
    generateExtension( fullfile(L.folder, L.name) );
    fprintf("Installed extension ""%s"".\n", extensionName)
end

function repoFolder = downloadZippedRepo(githubUrl, targetFolder, updateFlag, throwErrorIfFails)
%downloadZippedRepo Download zipped repo

    if nargin < 3; updateFlag = false; end
    if nargin < 4; throwErrorIfFails = false; end

    if isa(updateFlag, 'char') && strcmp(updateFlag, 'update')
        updateFlag = true;
    end
    
    % Create a temporary path for storing the downloaded file.
    [~, ~, fileType] = fileparts(githubUrl);
    tempFilepath = [tempname, fileType];
    
    % Download the file containing the zipped repository
    try
        tempFilepath = websave(tempFilepath, githubUrl);
        fileCleanupObj = onCleanup( @(fname) delete(tempFilepath) );
    catch ME
        if throwErrorIfFails
            rethrow(ME)
        end
    end

    unzippedFiles = unzip(tempFilepath, tempdir);
    unzippedFolder = unzippedFiles{1};
    if endsWith(unzippedFolder, filesep)
        unzippedFolder = unzippedFolder(1:end-1);
    end
    
    [~, repoFolderName] = fileparts(unzippedFolder);
    targetFolder = fullfile(targetFolder, repoFolderName);

    if updateFlag && isfolder(targetFolder)
        
        % Delete current version
        if isfolder(targetFolder)
            if contains(path, fullfile(targetFolder, filesep))
                pathList = strsplit(path, pathsep);
                pathList_ = pathList(startsWith(pathList, fullfile(targetFolder, filesep)));
                rmpath(strjoin(pathList_, pathsep))
            end
            try
                rmdir(targetFolder, 's')
            catch
                warning('Could not remove old installation... Please report')
            end
        end
    else
        % pass
    end

    movefile(unzippedFolder, targetFolder);
    
    % Delete the temp zip file
    clear fileCleanupObj

    repoFolder = targetFolder;
end
