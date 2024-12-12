function repoFolder = downloadZippedRepo(githubUrl, targetFolder)
%downloadZippedRepo - Download a zipped repository
    
    % Create a temporary path for storing the downloaded file.
    [~, ~, fileType] = fileparts(githubUrl);
    tempFilepath = [tempname, fileType];
    
    % Download the file containing the zipped repository
    tempFilepath = websave(tempFilepath, githubUrl);
    fileCleanupObj = onCleanup( @(fname) delete(tempFilepath) );

    unzippedFiles = unzip(tempFilepath, tempdir);
    unzippedFolder = unzippedFiles{1};
    if endsWith(unzippedFolder, filesep)
        unzippedFolder = unzippedFolder(1:end-1);
    end
    
    [~, repoFolderName] = fileparts(unzippedFolder);
    targetFolder = fullfile(targetFolder, repoFolderName);

    if isfolder(targetFolder)
        if contains(path, fullfile(targetFolder, filesep))
            pathList = strsplit(path, pathsep);
            pathList_ = pathList(startsWith(pathList, fullfile(targetFolder, filesep)));
            rmpath(strjoin(pathList_, pathsep))
        end
        try
            rmdir(targetFolder, 's')
        catch
            error('Could not delete previously downloaded extension which is located here:\n"%s"', targetFolder)
        end
    else
        % pass
    end

    movefile(unzippedFolder, targetFolder);
    
    % Delete the temp zip file
    clear fileCleanupObj

    repoFolder = targetFolder;
end
