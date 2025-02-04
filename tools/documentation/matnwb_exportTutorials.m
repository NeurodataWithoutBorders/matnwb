function matnwb_exportTutorials(options)
% matnwb_exportTutorials - Export mlx tutorial files to the specified output format
%
% Note: This function will ignore the following live scripts:
%  - basicUsage.mlx : depends on output from convertTrials.m
%  - read_demo.mlx : depends on external data, potentially slow
%  - remote_read.mlx : Uses nwbRead on s3 url, potentially very slow]
%
%   To export all livescripts (assuming you have made sure the above-mentioned 
%   files will run) call the function with IgnoreFiles set to empty, i.e:
%       matnwb_exportTutorials(..., "IgnoreFiles", string.empty)

    arguments
        options.ExportFormat (1,:) string {mustStartWithDot} = [".m", ".html"]
        options.Expression (1,1) string = "*" % Filter by expression
        options.FileNames (1,:) string = string.empty % Filter by file names
        options.FilePaths (1,:) string = string.empty % Export specified files
        options.IgnoreFiles (1,:) string = ["basicUsage", "read_demo", "remote_read"];
        options.RunLivescript (1,1) logical = true
    end

    EXPORT_FOLDERS = dictionary(...
        '.m', fullfile(misc.getMatnwbDir, "tutorials", "private", "mcode"), ...
        '.html', fullfile(misc.getMatnwbDir, "docs", "source", "_static", "html", "tutorials") );
    
    [exportFormat, targetFolderNames] = deal(options.ExportFormat);

    targetFolderNames = extractAfter(targetFolderNames, ".");
    nwbTutorialDir = fullfile(misc.getMatnwbDir, "tutorials");
    targetFolderPaths = fullfile(nwbTutorialDir, targetFolderNames);
    
    for i = 1:numel(exportFormat)
        if isKey(EXPORT_FOLDERS, exportFormat(i))
            targetFolderPaths(i) = EXPORT_FOLDERS(exportFormat(i));
        end
        if ~isfolder(targetFolderPaths(i)); mkdir(targetFolderPaths(i)); end
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
        
    if ~isempty(options.IgnoreFiles)
        [~, fileNames] = fileparts(filePaths);
        [fileNames, iA] = setdiff(fileNames, options.IgnoreFiles, 'stable');
        filePaths = filePaths(iA);
    end

    % Go to a temporary directory, so that tutorials are exported in a
    % temporary folder which is cleaned up afterwards
    currentDir = pwd();
    cleanupWorkdir = onCleanup(@(fp) cd(currentDir));

    tempDir = fullfile(tempdir, 'nwbTutorials');
    if ~isfolder(tempDir); mkdir(tempDir); end
    disp('Changing into temporary directory:')
    cd(tempDir)

    cleanupDeleteTempFiles = onCleanup(@(fp) rmdir(tempDir, 's'));
    disp(tempDir)

    for i = 1:numel(filePaths)
        sourcePath = char( fullfile(filePaths(i)) );
        if options.RunLivescript
            fprintf('Running livescript "%s"\n', fileNames(i))

            matlab.internal.liveeditor.executeAndSave(sourcePath);
        end
        
        for j = 1:numel(exportFormat)
            targetFilePath = fullfile(targetFolderPaths(j), fileNames(i) + exportFormat(j));
            fprintf('Exporting livescript "%s" to "%s"\n', fileNames(i), exportFormat(j))
            export(sourcePath, targetFilePath);
            if strcmp(exportFormat(j), '.html')
                postProcessLivescriptHtml(targetFilePath)
            end
        end
    end
end

function mustStartWithDot(value)
    for i = 1:numel(value)
        assert(startsWith(value(i), '.'), ...
            'Value must be a file extension starting with a period, e.g ".html"')
    end
end
