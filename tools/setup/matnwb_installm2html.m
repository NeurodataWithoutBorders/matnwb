function matnwb_installm2html(projectDirectory)

    arguments
        projectDirectory (1,1) string {mustBeFolder}
    end

    % Define repository URL and target folder
    repoURL = 'https://github.com/gllmflndn/m2html.git'; 
    targetFolder = fullfile(projectDirectory, 'tools', 'external', 'm2html');
    
    % Step 1: Clone m2html into tools/external/
    if ~isfolder(targetFolder)
        fprintf('Cloning m2html into %s...\n', targetFolder);
        system(sprintf('git clone %s %s', repoURL, targetFolder));
        addpath(targetFolder); savepath()
        fprintf('Clone complete.\n');
    else
        fprintf('Target folder %s already exists. Skipping cloning step.\n', targetFolder);
    end
    
    % Step 2: Add tools/external to .git/info/exclude
    excludeFile = fullfile(projectDirectory, '.git', 'info', 'exclude');
    targetFolderRelative = fullfile('tools', 'external');
    if isfile(excludeFile)
        % Read current contents of the exclude file
        excludeContents = fileread(excludeFile);
        
        % Check if the path is already excluded
        if ~contains(excludeContents, targetFolderRelative)
            fprintf('Adding %s to .git/info/exclude...\n', targetFolderRelative);
            fid = fopen(excludeFile, 'a'); % Open for appending
            fprintf(fid, '\n%s\n', targetFolderRelative); % Add the path to the exclude file
            fclose(fid);
            fprintf('Path added to exclude file.\n');
        else
            fprintf('Path %s is already in the exclude file. Skipping.\n', targetFolderRelative);
        end
    else
        fprintf('Exclude file not found. Make sure you are in a Git repository.\n');
    end
end