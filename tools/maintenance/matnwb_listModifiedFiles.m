function modifiedFiles = matnwb_listModifiedFiles()
% matnwb_listModifiedFiles - Lists modified files in the repository using Git.
%
% This function identifies files modified in the current Git repository by
% executing a `git diff --name-only` command. The list of modified files is
% returned as a full file path relative to the repository root.
%
% Usage:
%   modifiedFiles = matnwb_listModifiedFiles()
%
% Inputs:
%   None
%
% Outputs:
%   modifiedFiles - (string array) A list of modified files in the repository,
%                   with absolute paths. If no modified files are detected,
%                   an empty string array is returned.
%
% Errors:
%   - Raises an error if Git fails or is unavailable.

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
