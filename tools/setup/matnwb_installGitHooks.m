function matnwb_installGitHooks(projectDirectory)
% matnwb_installGitHooks - Install git hooks
% Installs git hooks from the specified folder to the git project.
%
% Arguments:
%   projectDirectory (string): Root directory of the git project (Optional). 
%                              Default assumes this function is located two
%                              subfolder levels down from the root, e.g.,
%                              tools/githooks.

    arguments
        % Project directory - root directory for git project. Assumes this
        % function is three subfolder levels down from root directory, i.e
        % tools/setup/
        projectDirectory (1,1) string {mustBeFolder} = ...
            fileparts(fileparts(fileparts(mfilename('fullpath'))))
    end

    gitHooksSourceFolder = fullfile(projectDirectory, 'tools', 'githooks');

    % List all .m files in the githooks source folder
    L = dir(fullfile(gitHooksSourceFolder, '*.m'));

    % Define supported hook names
    supportedHookNames = ["pre-commit", "pre-push"];

    % Git hooks folder in the project directory
    gitHooksTargetFolder = fullfile(projectDirectory, '.git', 'hooks');

    % Ensure the git hooks folder exists
    if ~isfolder(gitHooksTargetFolder)
        error("installHooks:InvalidGitRepository", ...
              "The specified project directory does not contain a valid git repository.");
    end

    % Loop through the .m files and create symlinks for recognized hooks
    for i = 1:numel(L)
        [~, mFileName] = fileparts(L(i).name);

        % Convert the script name to a git hook name
        hookName = strrep(mFileName, '_', '-');

        % Check if the hook name is supported
        if ismember(hookName, supportedHookNames)
            targetPath = fullfile(gitHooksTargetFolder, hookName);
            
            scriptContent = fileread(fullfile(gitHooksSourceFolder, hookName));
            scriptContent = strrep(scriptContent, '{{matlabroot}}', matlabroot);

            fid = fopen(targetPath, "wt");
            fwrite(fid, scriptContent);
            fclose(fid);

            if isunix
                % Make the target executable
                system(sprintf('chmod +x "%s"', targetPath));
            end

            fprintf('Installed hook: %s -> %s\n', hookName, targetPath);
        else
            fprintf('Skipped unsupported hook: %s\n', hookName);
        end
    end
end
