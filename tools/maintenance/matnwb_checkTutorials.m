function matnwb_checkTutorials()
% matnwb_checkTutorials - Checks for modified MATLAB Live Script tutorial files 
% in the repository and executes tests and html exports if found.
%
% This function determines whether any tutorial files in the `tutorials`
% directory have been modified in the matnwb repository. If such files exist, 
% the function performs the following actions:
% 1. Runs unit tests matching the tutorial names.
% 2. Exports the modified tutorial files using the `matnwb_exportTutorials` 
% function.
%
% Usage:
%   matnwb_checkTutorials()
%
%   See also matnwb_listModifiedFiles, matnwb_exportTutorials

    tutorialFolder = fullfile(misc.getMatnwbDir, 'tutorials');

    modifiedFiles = matnwb_listModifiedFiles("all");

    isInTutorialFolder = startsWith(modifiedFiles, tutorialFolder);
    isLivescript = endsWith(modifiedFiles, ".mlx");

    tutorialFiles = modifiedFiles(isInTutorialFolder & isLivescript);

    if ~isempty(tutorialFiles)
        [~, fileNames] = fileparts(tutorialFiles);
        fileNames = string(fileNames) + ".mlx";
        nwbtest('Name', 'tests.unit.Tutorial*', 'ParameterName', fileNames')    
        matnwb_exportTutorials("FilePaths", tutorialFiles)
    end
end
