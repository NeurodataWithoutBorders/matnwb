function exportTutorials(options)
% exportTutorials - Export tutorial mlx files the specified output format

% see also fullfile(matlabroot, 'toolbox/matlab/codetools/+matlab/+internal')

    arguments
        options.ExportFormat (1,:) string {mustStartWithDot} = [".m", ".html"]
        options.Expression (1,1) string = "*" % Filter by expression
        options.FileNames (1,:) string = string.empty % Filter by file names
        options.FilePaths (1,:) string = string.empty % Export specified files
        options.IgnoreFiles (1,:) string = string.empty %["remote_read"] <- takes a long time to run
        options.RunLivescript (1,1) logical = true
    end
    
    [exportFormat, targetFolderNames] = deal(options.ExportFormat);

    targetFolderNames = extractAfter(targetFolderNames, ".");
    targetFolderNames(strcmp(targetFolderNames, "m")) = "mcode";

    nwbTutorialDir = fullfile(misc.getMatnwbDir, "tutorials");
    targetFolderPaths = fullfile(nwbTutorialDir, targetFolderNames);

    for folderPath = targetFolderPaths
        if ~isfolder(folderPath); mkdir(folderPath); end
    end
    
    if isempty(options.FilePaths)
        if endsWith(options.Expression, "*")
            expression = options.Expression + ".mlx";
        else
            expression = options.Expression + "*.mlx";
        end
    
        L = dir(fullfile(nwbTutorialDir, expression));
        filePaths = string( fullfile({L.folder}, {L.name}) );
    else
        filePaths = options.FilePaths;
    end

    [~, fileNames] = fileparts(filePaths);
    if ~isempty(options.FileNames)
        [fileNames, iA] = intersect(fileNames, options.FileNames, 'stable');
        filePaths = filePaths(iA);
    end

    % Go to a temporary directory, so that tutorials are exported in a
    % temporary folder which is cleaned up afterwards
    currentDir = pwd();
    cleanupWorkdir = onCleanup(@(fp) cd(currentDir));

    tempDir = fullfile(tempdir, 'nwbTutorials');
    if ~isfolder(tempDir); mkdir(tempDir); end
    cd(tempDir)

    cleanupDeleteTempFiles = onCleanup(@(fp) rmdir(tempDir, 's'));
    disp(tempDir)

    for i = 1:numel(filePaths)
        sourcePath = char( fullfile(filePaths(i)) );
        if options.RunLivescript
            matlab.internal.liveeditor.executeAndSave(sourcePath);
        end
        
        for j = 1:numel(exportFormat)
            targetPath = fullfile(targetFolderPaths(j), fileNames(i) + exportFormat(j));
            export(sourcePath, strrep(targetPath, '.mlx', exportFormat(j)));
        end
    end
end

function mustStartWithDot(value)
    for i = 1:numel(value)
        assert(startsWith(value(i), '.'), ...
            'Value must be a file extension starting with a period, e.g ".html"')
    end
end
