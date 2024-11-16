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

    isTutorialFile = startsWith(modifiedFiles, fullfile(misc.getMatnwbDir, 'tutorials'));
    isTutorialFile = isTutorialFile & endsWith(modifiedFiles, ".mlx");
    tutorialFiles = modifiedFiles(isTutorialFile);
    
    matnwb_exportTutorials("FilePaths", tutorialFiles)
end
