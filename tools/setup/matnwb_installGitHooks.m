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

    % Define supported hook names
    supportedHookNames = ["pre-commit", "pre-push"];

    % Git hooks folder in the project directory
    gitHooksTargetFolder = fullfile(projectDirectory, '.git', 'hooks');

    % Ensure the git hooks folder exists
    if ~isfolder(gitHooksTargetFolder)
        error("installHooks:InvalidGitRepository", ...
              "The specified project directory does not contain a valid git repository.");
    end

    for hookName = supportedHookNames
        if ismac
            postfix = "mac";
        elseif isunix
            postfix = "linux";
        elseif ispc
            postfix = "win";
        end
    
        listing = dir(fullfile(gitHooksSourceFolder, hookName+"-"+postfix));
        if ~isempty(listing)
            targetPath = fullfile(gitHooksTargetFolder, hookName);
            scriptContent = fileread(fullfile(gitHooksSourceFolder, listing.name));

            fid = fopen(targetPath, "wt");
            fwrite(fid, scriptContent);
            fclose(fid);

            if isunix
                % Make the target executable
                system(sprintf('chmod +x "%s"', targetPath));
            end
            fprintf('Installed hook: %s -> %s\n', hookName, targetPath);
        end
    end
end
