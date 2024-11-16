function matnwb_exportModifiedTutorials()
% matnwb_exportModifiedTutorials - Export modified livescript tutorials to html
%
% See also matnwb_exportTutorials

    if exist("isMATLABReleaseOlderThan", "file") == 2
        hasGitRepo = ~isMATLABReleaseOlderThan("R2023b");
    else
        hasGitRepo = false;
    end
    
    if hasGitRepo
        repo = gitrepo(misc.getMatnwbDir);
        modifiedFiles = repo.ModifiedFiles;
    else
        currentDir = pwd;
        cleanupObj = onCleanup(@(fp) cd(currentDir));
        cd(misc.getMatnwbDir)
        [status, cmdout] = system('git --no-pager diff --name-only');
        clear cleanupObj
        if status == 0
            modifiedFiles = splitlines(cmdout);
            modifiedFiles = string(modifiedFiles);
            modifiedFiles(modifiedFiles=="") = [];
            modifiedFiles = fullfile(misc.getMatnwbDir, modifiedFiles);
        else
            error('Could not use git to detect modified files.')
        end
    end

    isTutorialFile = startsWith(modifiedFiles, fullfile(misc.getMatnwbDir, 'tutorials'));
    isTutorialFile = isTutorialFile & endsWith(modifiedFiles, ".mlx");
    tutorialFiles = modifiedFiles(isTutorialFile);
    
    matnwb_exportTutorials("FilePaths", tutorialFiles)
end
