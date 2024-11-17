function modifiedFiles = matnwb_listModifiedFiles(mode)
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
%   mode - (string) [optional] Which mode to use. Options: "all" or "staged"
%                   Whether to list all modified files or only files staged for 
%                   commit. Default is "all".
%
% Outputs:
%   modifiedFiles - (string array) A list of modified files in the repository,
%                   with absolute paths. If no modified files are detected,
%                   an empty string array is returned.
%
% Errors:
%   - Raises an error if Git fails or is unavailable.
    
    arguments
        mode (1,1) string {mustBeMember(mode, ["staged", "all"])} = "all"
    end

    currentDir = pwd;
    cleanupObj = onCleanup(@(fp) cd(currentDir));

    cd(misc.getMatnwbDir)
    
    switch mode
        case "all"
            [status, cmdout] = system([...
                'git --no-pager diff --cached --name-only ', ...
                '&& git --no-pager diff --name-only | sort | uniq' ]);
        case "staged"
            [status, cmdout] = system('git --no-pager diff --cached --name-only');
    end
    clear cleanupObj

    if status == 0
        modifiedFiles = splitlines(cmdout);
        modifiedFiles = string(modifiedFiles);
        modifiedFiles(modifiedFiles=="") = [];
        modifiedFiles = removeHiddenFormatting(modifiedFiles);
        modifiedFiles = fullfile(misc.getMatnwbDir, modifiedFiles);
    else
        error('Could not use git to detect modified files.')
    end
end

function cleanText = removeHiddenFormatting(inputText)
    % Define the regex pattern for ANSI escape sequences
    ansiPattern = '\x1B\[[0-9;]*[a-zA-Z]';

    % Remove ANSI escape sequences using regexprep
    cleanText = regexprep(inputText, ansiPattern, '');
end
