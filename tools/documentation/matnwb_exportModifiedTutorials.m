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
        modifiedFiles = matnwb_listModifiedFiles();
    end

    tutorialFolder = fullfile(misc.getMatnwbDir, 'tutorials');
    isInTutorialFolder = startsWith(modifiedFiles, tutorialFolder);
    isLivescript = endsWith(modifiedFiles, ".mlx");
    
    tutorialFiles = modifiedFiles(isInTutorialFolder & isLivescript);

    filesToIgnore = ["basicUsage", "read_demo", "remote_read"];
    isIgnored = endsWith(tutorialFiles, filesToIgnore + ".mlx");
    if any(isIgnored)
        warning('Skipping export for the following files (see matnwb_exportTutorials):\n%s', ...
            strjoin("  - " + filesToIgnore(isIgnored) + ".mlx", newline))
    end

    matnwb_exportTutorials("FilePaths", tutorialFiles, "IgnoreFiles", filesToIgnore)
end
